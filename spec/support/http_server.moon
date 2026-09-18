-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- A minimal HTTP server for specs, built on GSocketService so it runs on the
-- same GLib main loop the specs already pump. It binds an ephemeral loopback
-- port, so nothing ever leaves the machine and CI needs no network.
--
--   server = HttpServer!
--   server\route '/hello', body: 'hi'
--   res = howl.io.http.get server\url '/hello'
--   server\stop!

SocketService = require 'ljglibs.gio.socket_service'
{:ref_ptr} = require 'ljglibs.gobject'
{:InputStream, :OutputStream} = howl.io
dispatch = howl.dispatch
timer = howl.timer

append = table.insert

sleep = (seconds) ->
  handle = dispatch.park 'http-server-delay'
  timer.after_exactly seconds, -> dispatch.resume_or_clear handle
  dispatch.wait handle

parse_request = (text) ->
  head, _ = text\match '^(.-)\r?\n\r?\n'
  return nil unless head
  lines = [l for l in head\gmatch '[^\r\n]+']
  method, target, version = lines[1]\match '^(%S+)%s+(%S+)%s+(%S+)$'
  headers = {}
  for i = 2, #lines
    name, value = lines[i]\match '^([^:]+):%s*(.-)%s*$'
    headers[name\lower!] = value if name

  { :method, :target, :version, :headers, request_line: lines[1] }

chunked_body = (pieces, trailers) ->
  out = {}
  for piece in *pieces
    append out, "#{string.format '%x', #piece}\r\n#{piece}\r\n"

  append out, '0\r\n'
  if trailers
    append out, "#{t}\r\n" for t in *trailers
  append out, '\r\n'
  table.concat out

class HttpServer
  new: =>
    @service = SocketService!
    @port = @service\add_any_inet_port nil
    @routes = {}
    @requests = {}
    -- connections currently being served, held so they are not collected
    @live = {}
    -- anything a handler raised, so a spec can see why a response never arrived
    @errors = {}
    @stopped = false
    @service\connect_for @, 'incoming', self._on_incoming
    @service\start!

  url: (path = '/') => "http://127.0.0.1:#{@port}#{path}"

  -- spec: { status, reason, headers, body, chunked, trailers, delay, close_early }
  route: (path, spec = {}) =>
    @routes[path] = spec
    @

  -- responds with exactly these bytes, for malformed-response cases
  raw: (path, bytes) =>
    @routes[path] = { raw: bytes }
    @

  stop: =>
    return if @stopped
    @stopped = true
    @service\stop!
    @service\close!

  _lookup: (target) =>
    path = target\match '^([^?]*)' or target
    @routes[target] or @routes[path]

  -- connect_for hands the handler (self, emitting_instance, ...signal_params),
  -- so the service arrives before the connection
  _on_incoming: (service, connection) =>
    return true if @stopped

    -- GIO only lends the connection for the duration of the callback, and the
    -- dispatcher runs this handler in its own coroutine - so the moment we park
    -- on a read the callback returns and the connection would be dropped. Take
    -- a reference and keep it alive until we are done with it.
    connection = ref_ptr connection
    @live[connection] = true

    ok, err = pcall -> @_serve connection
    -- Closing the GIOStream, not just the output stream, is what actually
    -- shuts the socket down - and a client reading an eof-framed body waits
    -- for exactly that.
    pcall -> connection\close!
    @live[connection] = nil
    append @errors, err unless ok
    true

  _serve: (connection) =>
    input = InputStream connection.input_stream
    output = OutputStream connection.output_stream

    buffer = ''
    local request

    while true
      request = parse_request buffer
      break if request
      data = input\read 4096
      break unless data and #data > 0
      buffer ..= data

    unless request and request.target
      @_write output, status: 400, reason: 'Bad Request', body: 'unparseable request'
      return

    length = tonumber request.headers['content-length']
    if length and length > 0
      body_start = buffer\find('\r\n\r\n', 1, true)
      body = body_start and buffer\sub(body_start + 4) or ''
      while #body < length
        data = input\read 4096
        break unless data and #data > 0
        body ..= data

      request.body = body

    append @requests, request

    spec = @_lookup request.target
    unless spec
      @_write output, status: 404, reason: 'Not Found', body: 'no such route'
      return

    sleep spec.delay if spec.delay

    if spec.close_early
      pcall -> output\close!
      return

    @_write output, spec, request

  _write: (output, spec, request) =>
    if spec.raw
      pcall -> output\write spec.raw
      pcall -> output\close!
      return

    status = spec.status or 200
    reason = spec.reason or 'OK'
    headers = {}
    if spec.headers
      headers[k] = v for k, v in pairs spec.headers

    local body
    if spec.chunked
      body = chunked_body spec.chunked, spec.trailers
      headers['Transfer-Encoding'] or= 'chunked'
    else
      body = spec.body or ''
      -- omitting Content-Length is how the eof-framing case is exercised
      headers['Content-Length'] or= tostring #body unless spec.no_content_length

    -- HEAD responses carry headers but no body
    body = '' if request and request.method == 'HEAD'

    lines = {"HTTP/1.1 #{status} #{reason}"}
    keys = [k for k in pairs headers]
    table.sort keys
    for key in *keys
      append lines, "#{key}: #{headers[key]}"

    pcall -> output\write table.concat(lines, '\r\n') .. '\r\n\r\n' .. body
    pcall -> output\close!

HttpServer
