-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- HTTP/1.1 response parsing: status line, header block, body framing and the
-- chunked transfer-encoding decoder.
--
-- Deliberately pure - no FFI, no I/O, no sockets. Socket reads arrive in chunks
-- with arbitrary boundaries, so everything here is incremental and must behave
-- identically whether a payload arrives in one piece or a byte at a time. That
-- property is what the specs assert, and keeping this module I/O-free is what
-- makes asserting it possible.

headers_mod = howl.io.headers
append = table.insert

-- Caps. A response that blows past these is either broken or hostile; either way
-- we stop rather than buffer without bound.
MAX_HEAD_SIZE = 64 * 1024
MAX_CHUNK_LINE = 1024

-- Sloppy servers exist; accept bare LF as well as the CRLF the spec requires.
HEAD_TERMINATORS = {'\r\n\r\n', '\n\n'}

find_head_end = (data, start = 1) ->
  best, best_len = nil, nil
  for terminator in *HEAD_TERMINATORS
    pos = data\find terminator, start, true
    if pos and (not best or pos < best)
      best, best_len = pos, #terminator

  best, best_len

parse_status_line = (line) ->
  line = line\gsub '\r$', ''
  version, status, reason = line\match '^HTTP/(%d+%.%d+)%s+(%d%d%d)%s*(.*)$'
  unless version
    return nil, "malformed HTTP status line: #{string.format '%q', line}"

  { :version, status: tonumber(status), reason: reason or '' }

-- Parses a header block into a headers collection. Continuation (obs-fold) lines
-- are joined onto the previous value; a name that is not a valid token is refused
-- rather than passed along, since that is how a smuggled header gets through.
parse_headers = (block) ->
  h = headers_mod.create!
  pending_name, pending_value = nil, nil

  flush = ->
    if pending_name
      h\add pending_name, (pending_value\gsub('%s+$', ''))
      pending_name, pending_value = nil, nil

  for raw in block\gmatch '[^\n]+'
    line = raw\gsub '\r$', ''
    continue if line == ''

    if line\match '^[ \t]'
      unless pending_name
        return nil, 'HTTP header block starts with a continuation line'
      pending_value ..= ' ' .. line\gsub('^[ \t]+', '')
    else
      flush!
      name, value = line\match '^([^:]*):(.*)$'
      unless name
        return nil, "malformed HTTP header line: #{string.format '%q', line}"
      unless headers_mod.is_valid_name name
        return nil, "invalid HTTP header name in response: #{string.format '%q', name}"
      pending_name = name
      pending_value = value\gsub '^[ \t]+', ''

  flush!
  h

-- Returns the parsed head and whatever follows it, or:
--   nil, nil  - incomplete, feed more data
--   nil, err  - malformed
-- 1xx interim responses are skipped: a server may send "100 Continue" unsolicited
-- even though we never send an Expect header.
parse_head = (data) ->
  pos = 1

  while true
    head_end, term_len = find_head_end data, pos
    unless head_end
      if #data - pos + 1 > MAX_HEAD_SIZE
        return nil, "HTTP response head exceeds #{MAX_HEAD_SIZE} bytes"
      return nil, nil

    block = data\sub pos, head_end - 1
    nl = block\find '\n', 1, true
    status_line = nl and block\sub(1, nl - 1) or block
    header_block = nl and block\sub(nl + 1) or ''

    info, err = parse_status_line status_line
    return nil, err unless info

    if info.status >= 100 and info.status < 200
      pos = head_end + term_len
      continue

    hdrs, herr = parse_headers header_block
    return nil, herr unless hdrs

    info.headers = hdrs
    return info, data\sub(head_end + term_len)

-- We advertise Accept-Encoding: identity and do not implement gzip. Some CDNs
-- ignore that, and handing the caller compressed bytes would look like a parse
-- bug on their side, so refuse explicitly.
check_content_encoding = (hdrs) ->
  enc = hdrs['content-encoding']
  return true unless enc
  enc = enc\lower!\gsub '%s', ''
  return true if enc == '' or enc == 'identity'
  nil, "unsupported Content-Encoding '#{enc}' (Howl requests identity only)"

-- Decides how the body is delimited. Returns one of:
--   'none' | 'chunked' | 'eof' | { length: n }
body_framing = (status, method, hdrs) ->
  method = (method or 'GET')\upper!
  if method == 'HEAD' or status == 204 or status == 304 or (status >= 100 and status < 200)
    return 'none'

  te = hdrs['transfer-encoding']
  lengths = hdrs\all 'content-length'

  if te
    encodings = [e\lower!\gsub('%s', '') for e in te\gmatch '[^,]+']
    is_chunked = encodings[#encodings] == 'chunked'
    unless is_chunked
      return nil, "unsupported Transfer-Encoding '#{te}'"

    -- Both framings present is the classic request-smuggling ambiguity. Refusing
    -- is one line and closes the whole class.
    if #lengths > 0
      return nil, 'response specifies both Transfer-Encoding and Content-Length'

    return 'chunked'

  if #lengths > 0
    length = tonumber lengths[1]
    unless length and length >= 0 and length % 1 == 0
      return nil, "malformed Content-Length: #{string.format '%q', lengths[1]}"

    for i = 2, #lengths
      unless tonumber(lengths[i]) == length
        return nil, 'response specifies conflicting Content-Length values'

    return { :length }

  'eof'

-- Incremental chunked decoder. Feed it arbitrary byte runs; it returns whatever
-- it could decode from what it has so far. Splits may fall anywhere, including
-- mid-size-line and between a chunk and its trailing CRLF.
class ChunkedDecoder
  new: =>
    @buffer = ''
    @state = 'size'
    @remaining = 0
    @done = false
    @trailers = {}

  -- returns decoded_data, done  /  raises on a malformed stream
  feed: (data) =>
    @buffer ..= data if data and #data > 0
    out = {}

    while not @done
      if @state == 'size'
        pos = @buffer\find '\n', 1, true
        unless pos
          if #@buffer > MAX_CHUNK_LINE
            error "malformed chunked encoding: chunk size line exceeds #{MAX_CHUNK_LINE} bytes", 0
          break

        if pos > MAX_CHUNK_LINE
          error "malformed chunked encoding: chunk size line exceeds #{MAX_CHUNK_LINE} bytes", 0

        line = @buffer\sub(1, pos - 1)\gsub '\r$', ''
        @buffer = @buffer\sub pos + 1

        -- everything after ';' is a chunk extension, which we ignore
        size_hex = line\match '^%x+'
        unless size_hex
          error "malformed chunked encoding: bad chunk size #{string.format '%q', line}", 0

        @remaining = tonumber size_hex, 16
        @state = @remaining == 0 and 'trailer' or 'data'

      elseif @state == 'data'
        break if #@buffer == 0
        take = math.min @remaining, #@buffer
        append out, @buffer\sub(1, take)
        @buffer = @buffer\sub take + 1
        @remaining -= take
        @state = 'crlf' if @remaining == 0

      elseif @state == 'crlf'
        break if #@buffer == 0
        if @buffer\sub(1, 2) == '\r\n'
          @buffer = @buffer\sub 3
          @state = 'size'
        elseif @buffer\sub(1, 1) == '\n'
          @buffer = @buffer\sub 2
          @state = 'size'
        elseif @buffer == '\r'
          break -- could still become '\r\n'
        else
          error 'malformed chunked encoding: missing CRLF after chunk data', 0

      elseif @state == 'trailer'
        pos = @buffer\find '\n', 1, true
        break unless pos
        line = @buffer\sub(1, pos - 1)\gsub '\r$', ''
        @buffer = @buffer\sub pos + 1
        if line == ''
          @state = 'done'
          @done = true
        else
          append @trailers, line

      else
        break

    table.concat(out), @done

  -- anything left after the terminating chunk; non-empty only if a server sent
  -- more than one response on the connection, which we never ask it to do
  leftover: => @done and @buffer or ''

{
  :parse_status_line
  :parse_headers
  :parse_head
  :body_framing
  :check_content_encoding
  :ChunkedDecoder
  :MAX_HEAD_SIZE
  :MAX_CHUNK_LINE
}
