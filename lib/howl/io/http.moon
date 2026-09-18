-- Copyright 2025 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- An HTTP/1.1 client built on GIO. No new dependency: libgio is already linked
-- into the binary and glib-networking supplies TLS, so this costs nothing at
-- build or package time.
--
-- The API looks synchronous but never blocks the UI. Every operation issues a
-- GIO *_async call and parks its coroutine (howl.dispatch), exactly as
-- howl.io.Process does, so it must be called from inside a coroutine. Command
-- handlers already are.
--
--   res = howl.io.http.get 'https://example.com/x'
--   res = howl.io.http.post url, json: {a: 1}
--   howl.io.http.download url, howl.io.File '/tmp/x'
--
-- Deliberately not implemented: gzip, keep-alive, cookies, auth helpers. We send
-- 'Connection: close' and 'Accept-Encoding: identity' and refuse anything else
-- rather than half-supporting it.

ffi = require 'ffi'
json = require 'lunajson'
SocketClient = require 'ljglibs.gio.socket_client'
cancellables = require 'ljglibs.gio.cancellable'

{:InputStream, :OutputStream, :File} = howl.io
url_mod = howl.io.url
headers_mod = howl.io.headers
message = howl.io.http_message
dispatch = howl.dispatch
timer = howl.timer

C = ffi.C
append = table.insert

READ_SIZE = 8192
-- how much of a redirect's body we will read and throw away before giving up
REDIRECT_DRAIN_LIMIT = 64 * 1024

REDIRECT_STATUSES = {
  [301]: true, [302]: true, [303]: true, [307]: true, [308]: true
}

-- Host, Connection and the framing headers are ours to set; letting a caller
-- override them would either break framing or lie about the peer.
RESERVED_HEADERS = {
  host: true
  connection: true
  'content-length': true
  'transfer-encoding': true
}

setting = (name, fallback) ->
  ok, value = pcall -> howl.config[name]
  return fallback unless ok and value != nil
  value

-- GError domains, resolved lazily: a code only means something paired with one
local IO_ERROR_DOMAIN, TLS_ERROR_DOMAIN

error_domains = ->
  unless IO_ERROR_DOMAIN
    IO_ERROR_DOMAIN = tonumber C.g_io_error_quark!
    TLS_ERROR_DOMAIN = tonumber C.g_tls_error_quark!

  IO_ERROR_DOMAIN, TLS_ERROR_DOMAIN

describe_connect_error = (target, msg, code, domain) ->
  io_domain, tls_domain = error_domains!
  domain = domain and tonumber domain
  code = code and tonumber code

  if domain == io_domain and code == tonumber(C.G_IO_ERROR_CANCELLED)
    return "#{target.url}: timed out"

  return "#{target.url}: TLS handshake failed: #{msg}" if domain == tls_domain
  "#{target.url}: #{msg}"

-- Runs a parked read, reporting cancellation as the timeout it actually was
-- rather than as a raw GIO error.
guarded = (target, state, f) ->
  ok, ret = pcall f
  return ret if ok
  error "#{target.url}: timed out", 0 if state.timed_out
  error "#{target.url}: #{ret}", 0

class Connection
  new: (@target, @opts, @cancellable) =>
    @client = SocketClient!
    @client.tls = @target.scheme == 'https'
    @client.timeout = @opts.connect_timeout
    @client.enable_proxy = @opts.proxy_enabled != false
    @buffer = ''

  connect: =>
    if @client.tls and not SocketClient.tls_supported!
      error "#{@target.url}: HTTPS is unavailable - no TLS backend found (install glib-networking)", 0

    handle = dispatch.park "http-connect-#{@target.host}"

    @client\connect_to_uri_async @target.url, @target.default_port, @cancellable,
      (ok, ret, code, domain) ->
        if ok
          dispatch.resume handle, ret
        else
          dispatch.resume handle, nil, ret, code, domain

    conn, msg, code, domain = dispatch.wait handle
    error describe_connect_error(@target, msg, code, domain), 0 unless conn

    -- These must stay reachable for the whole request: gc_ptr attached an
    -- ffi.gc finalizer, and letting the connection go while an async read is
    -- outstanding would unref it under the callback.
    @connection = conn
    -- the cancellable goes to the streams too, not just to connect: a deadline
    -- that cannot interrupt a read is no deadline at all
    @input = InputStream conn.input_stream, nil, @cancellable
    @output = OutputStream conn.output_stream, @cancellable
    @

  write: (data) => @output\write data

  -- pulls one more read's worth into the buffer; false at EOF
  fill: =>
    data = @input\read READ_SIZE
    return false unless data and #data > 0
    @buffer ..= data
    true

  close: =>
    pcall -> @input\close! if @input
    pcall -> @output\close! if @output
    @connection = nil
    @input = nil
    @output = nil

class Response
  new: (opts) =>
    @status = opts.status
    @status_text = opts.reason
    @http_version = opts.version
    @headers = opts.headers
    @body = opts.body
    @url = opts.url
    @request_url = opts.request_url
    @redirects = opts.redirects or {}
    @file = opts.file
    @ok = @status >= 200 and @status < 300

    content_type = @headers['content-type']
    @content_type = content_type and (content_type\match('^[^;]*')\gsub '%s', '') or nil
    @content_length = tonumber @headers['content-length']

  json: =>
    error "#{@url}: response has no body to decode as JSON", 2 unless @body
    ok, decoded = pcall json.decode, @body
    error "#{@url}: response is not valid JSON", 2 unless ok
    decoded

  raise_for_status: =>
    return @ if @ok
    error "#{@url}: HTTP #{@status} #{@status_text}", 2

  __tostring: =>
    s = "HTTP #{@status} #{@status_text}"
    s ..= " (#{@content_type})" if @content_type
    s

-- Checked up front, before a socket is opened: a CRLF smuggled into a header
-- value must never reach the wire, and there is no point connecting first.
validate_caller_headers = (caller_headers) ->
  return unless caller_headers

  for name, value in pairs caller_headers
    unless headers_mod.is_valid_name name
      error "invalid HTTP header name: #{string.format '%q', tostring name}", 0

    unless headers_mod.is_valid_value tostring value
      error "invalid value for HTTP header '#{name}': #{string.format '%q', tostring value}", 0

    if RESERVED_HEADERS[name\lower!]
      error "the '#{name}' header is set by howl.io.http and cannot be overridden", 0

build_head = (method, target, body, caller_headers, opts) ->
  h = headers_mod.create!
  h\set 'Host', target.authority
  h\set 'User-Agent', opts.user_agent
  -- we do not implement gzip; asking for identity and refusing anything else is
  -- better than handing the caller bytes it cannot read
  h\set 'Accept-Encoding', 'identity'
  h\set 'Connection', 'close'
  h\set 'Content-Length', tostring(#body) if body

  if caller_headers
    h\set name, tostring(value) for name, value in pairs caller_headers

  lines = {"#{method} #{target.request_target} HTTP/1.1"}
  for name, value in h\each!
    append lines, "#{name}: #{value}"

  table.concat(lines, '\r\n') .. '\r\n\r\n'

-- parse_head returns (head, rest) on success, (nil, err) on a malformed
-- response and (nil, nil) when more data is needed - head being nil is what
-- disambiguates the second value.
read_head = (conn, target, state) ->
  while true
    head, rest_or_err = message.parse_head conn.buffer
    if head
      conn.buffer = rest_or_err
      return head

    error "#{target.url}: #{rest_or_err}", 0 if rest_or_err

    unless guarded target, state, -> conn\fill!
      error "#{target.url}: connection closed before the response headers were complete", 0

check_size = (target, size, max_size) ->
  if max_size > 0 and size > max_size
    error "#{target.url}: response exceeds the #{max_size} byte limit", 0

-- Reads the body, handing each piece to sink. Keeping the sink abstract is what
-- lets download() stream straight to disk instead of buffering.
read_body = (conn, target, framing, state, opts, sink) ->
  max_size = opts.max_size or 0
  total = 0

  emit = (piece) ->
    return if not piece or #piece == 0
    total += #piece
    check_size target, total, max_size
    sink piece
    opts.on_progress total, state.expected if opts.on_progress

  return 0 if framing == 'none'

  if framing == 'chunked'
    decoder = message.ChunkedDecoder!
    while true
      ok, decoded, done = pcall decoder.feed, decoder, conn.buffer
      error "#{target.url}: #{decoded}", 0 unless ok
      conn.buffer = ''
      emit decoded
      return total if done
      unless guarded target, state, -> conn\fill!
        error "#{target.url}: connection closed mid-chunk", 0

  if type(framing) == 'table'
    expected = framing.length
    state.expected = expected
    check_size target, expected, max_size

    while total < expected
      if #conn.buffer > 0
        take = math.min expected - total, #conn.buffer
        emit conn.buffer\sub(1, take)
        conn.buffer = conn.buffer\sub take + 1
      else
        unless guarded target, state, -> conn\fill!
          error "#{target.url}: connection closed after #{total} of #{expected} bytes", 0

    return total

  -- 'eof': the body runs until the server closes the connection
  while true
    if #conn.buffer > 0
      emit conn.buffer
      conn.buffer = ''

    break unless guarded target, state, -> conn\fill!

  total

-- One request/response exchange, with no redirect handling. Returns a context
-- whose body has not been read yet, plus the cleanup to run once it has.
perform = (method, target, body, opts) ->
  state = { timed_out: false }
  cancellable = opts.cancellable
  local timeout_handle

  -- A fresh cancellable and timer per hop: reusing one across redirects would
  -- leave later hops with no deadline at all.
  if cancellable == nil and opts.timeout and opts.timeout > 0
    cancellable = cancellables.create!
    timeout_handle = timer.after_exactly opts.timeout, ->
      state.timed_out = true
      cancellables.cancel cancellable

  conn = Connection target, opts, cancellable
  cleanup = ->
    timer.cancel timeout_handle if timeout_handle
    conn\close!

  ok, result = pcall ->
    conn\connect!
    conn\write build_head(method, target, body, opts.headers, opts)
    conn\write body if body

    head = read_head conn, target, state

    encoding_ok, encoding_err = message.check_content_encoding head.headers
    error "#{target.url}: #{encoding_err}", 0 unless encoding_ok

    framing, framing_err = message.body_framing head.status, method, head.headers
    error "#{target.url}: #{framing_err}", 0 unless framing

    { :head, :framing, :conn, :state }

  unless ok
    cleanup!
    error result, 0

  result.cleanup = cleanup
  result

read_into = (ctx, target, opts, sink) ->
  ok, err = pcall read_body, ctx.conn, target, ctx.framing, ctx.state, opts, sink
  unless ok
    ctx.cleanup!
    error err, 0

-- Drains a redirect's body so the exchange completes, but refuses to read a huge
-- error page just to throw it away.
drain = (ctx, target) ->
  pcall read_body, ctx.conn, target, ctx.framing, ctx.state, {max_size: REDIRECT_DRAIN_LIMIT}, ->

next_target = (current, head, method, body) ->
  location = head.headers['location']
  return nil unless location and location != ''

  target, err = url_mod.resolve current, location
  error "#{current.url}: invalid redirect target '#{location}': #{err}", 0 unless target

  unless target.scheme == 'http' or target.scheme == 'https'
    error "#{current.url}: refusing to follow a redirect to '#{target.scheme}'", 0

  if current.scheme == 'https' and target.scheme == 'http'
    error "#{current.url}: refusing to follow a redirect from https to http (#{target.url})", 0

  status = head.status
  -- 303 always becomes GET, and so does 301/302 on a POST - that is what every
  -- other client does and what callers expect. 307/308 preserve method and body.
  if status == 303 or ((status == 301 or status == 302) and method != 'GET' and method != 'HEAD')
    method, body = 'GET', nil

  target, method, body

same_origin = (a, b) ->
  a.scheme == b.scheme and a.host == b.host and a.port == b.port

-- Credentials must never follow a redirect to a different origin.
strip_cross_origin_headers = (header_table, current, target) ->
  return header_table if not header_table or same_origin current, target

  kept = {}
  for name, value in pairs header_table
    lower = name\lower!
    unless lower == 'authorization' or lower == 'cookie' or lower == 'proxy-authorization'
      kept[name] = value

  kept

body_from_opts = (opts) ->
  provided = 0
  provided += 1 if opts.body != nil
  provided += 1 if opts.json != nil
  provided += 1 if opts.form != nil
  error 'give at most one of body, json or form', 0 if provided > 1

  return json.encode(opts.json), 'application/json' if opts.json != nil
  return url_mod.build_query(opts.form), 'application/x-www-form-urlencoded' if opts.form != nil
  return tostring(opts.body), nil if opts.body != nil
  nil, nil

response_from = (head, target, request_url, redirects, body) ->
  Response {
    status: head.status
    reason: head.reason
    version: head.version
    headers: head.headers
    :body
    url: target.url
    :request_url
    :redirects
  }

request = (opts) ->
  error 'howl.io.http.request requires an options table', 2 unless type(opts) == 'table'

  _, is_main = coroutine.running!
  if is_main
    error 'howl.io.http must be called from a coroutine - wrap the call in howl.dispatch.launch', 2

  method = (opts.method or 'GET')\upper!
  unless headers_mod.is_valid_name method
    error "invalid HTTP method: #{string.format '%q', tostring opts.method}", 2

  target, err = url_mod.parse opts.url
  error err, 2 unless target

  unless target.scheme == 'http' or target.scheme == 'https'
    error "howl.io.http only supports http and https, not '#{target.scheme}'", 2

  if target.userinfo
    error "credentials in a URL are not sent; use an Authorization header instead (#{target.url})", 2

  if opts.query
    query = url_mod.build_query opts.query
    if query != ''
      separator = target.query and '&' or '?'
      target, err = url_mod.parse "#{target.url}#{separator}#{query}"
      error err, 2 unless target

  body, content_type = body_from_opts opts

  request_headers = {}
  if opts.headers
    request_headers[k] = v for k, v in pairs opts.headers
  if content_type and not request_headers['Content-Type'] and not request_headers['content-type']
    request_headers['Content-Type'] = content_type

  validate_caller_headers request_headers

  max_redirects = opts.max_redirects
  max_redirects = setting('http_max_redirects', 5) if max_redirects == nil

  call_opts = {
    timeout: opts.timeout or setting('http_timeout', 30)
    connect_timeout: opts.connect_timeout or 10
    max_size: opts.max_size or setting('http_max_response_size', 25 * 1024 * 1024)
    user_agent: opts.user_agent or setting('http_user_agent', 'Howl')
    proxy_enabled: opts.proxy_enabled
    cancellable: opts.cancellable
    on_progress: opts.on_progress
    headers: request_headers
  }
  call_opts.proxy_enabled = setting('http_proxy_enabled', true) if call_opts.proxy_enabled == nil

  request_url = target.url
  redirects = {}
  hops = 0

  while true
    ctx = perform method, target, body, call_opts
    head = ctx.head

    if REDIRECT_STATUSES[head.status] and max_redirects > 0
      if hops >= max_redirects
        ctx.cleanup!
        error "#{request_url}: too many redirects (#{max_redirects})", 0

      redirect_target, redirect_method, redirect_body = next_target target, head, method, body
      if redirect_target
        drain ctx, target
        ctx.cleanup!
        append redirects, target.url
        call_opts.headers = strip_cross_origin_headers call_opts.headers, target, redirect_target
        target, method, body = redirect_target, redirect_method, redirect_body
        hops += 1
        continue

    -- a download streams to its sink rather than buffering the body
    if opts.sink
      read_into ctx, target, call_opts, opts.sink
      ctx.cleanup!
      return response_from head, target, request_url, redirects, nil

    pieces = {}
    read_into ctx, target, call_opts, (piece) -> append pieces, piece
    ctx.cleanup!

    res = response_from head, target, request_url, redirects, table.concat(pieces)
    res\raise_for_status! if opts.expect_success
    return res

with_defaults = (url, method, opts) ->
  o = {}
  o[k] = v for k, v in pairs opts
  o.url = url
  o.method = method
  o

get = (url, opts = {}) -> request with_defaults(url, 'GET', opts)

head_request = (url, opts = {}) -> request with_defaults(url, 'HEAD', opts)

post = (url, body, opts = {}) ->
  o = with_defaults url, 'POST', opts
  if type(body) == 'table'
    o[k] = v for k, v in pairs body
  elseif body != nil
    o.body = body

  request o

-- Streams a response body straight to a file. Writes to '<target>.part' and
-- renames on success, so an interrupted download never leaves behind a file that
-- looks complete.
download = (url, target, opts = {}) ->
  path = type(target) == 'string' and target or tostring target
  part = "#{path}.part"

  fh, open_err = io.open part, 'wb'
  error "cannot write to '#{part}': #{open_err}", 2 unless fh

  o = with_defaults url, opts.method or 'GET', opts
  o.sink = (piece) -> fh\write piece
  -- a download is unbounded unless the caller says otherwise
  o.max_size = opts.max_size or 0

  ok, res = pcall request, o
  fh\close!

  unless ok
    os.remove part
    error res, 0

  unless res.ok
    os.remove part
    error "#{res.url}: HTTP #{res.status} #{res.status_text}", 2

  renamed, rename_err = os.rename part, path
  unless renamed
    os.remove part
    error "cannot move '#{part}' to '#{path}': #{rename_err}", 2

  res.file = File path
  res

{
  :request
  :get
  :post
  :download
  head: head_request
  :Response
}
