-- Copyright 2025 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

hm = howl.io.http_message
{:parse_status_line, :parse_headers, :parse_head, :body_framing, :check_content_encoding, :ChunkedDecoder} = hm
{:create} = howl.io.headers

-- feeds a payload one byte at a time, which is what a socket read boundary
-- landing in the worst possible place looks like
decode_bytewise = (payload) ->
  d = ChunkedDecoder!
  out = {}
  for i = 1, #payload
    chunk, done = d\feed payload\sub(i, i)
    out[#out + 1] = chunk
    break if done

  table.concat(out), d

describe 'http_message', ->
  describe 'parse_status_line(line)', ->
    it 'parses version, status and reason', ->
      assert.same {version: '1.1', status: 200, reason: 'OK'},
        parse_status_line 'HTTP/1.1 200 OK'

    it 'tolerates a missing reason phrase', ->
      assert.same {version: '1.1', status: 204, reason: ''},
        parse_status_line 'HTTP/1.1 204'

    it 'handles a multi-word reason', ->
      assert.equal 'Not Found', parse_status_line('HTTP/1.1 404 Not Found').reason

    it 'handles HTTP/1.0 and a trailing CR', ->
      assert.same {version: '1.0', status: 200, reason: 'OK'},
        parse_status_line 'HTTP/1.0 200 OK\r'

    it 'rejects garbage', ->
      for line in *{'', 'garbage', 'HTTP/1.1 20 OK', 'ICY 200 OK', 'HTTP/1.1 OK'}
        status, err = parse_status_line line
        assert.is_nil status
        assert.matches 'malformed HTTP status line', err

  describe 'parse_headers(block)', ->
    it 'parses a simple block', ->
      h = parse_headers 'Content-Type: text/plain\r\nContent-Length: 3\r\n'
      assert.equal 'text/plain', h['content-type']
      assert.equal '3', h['content-length']

    it 'tolerates a missing space after the colon and bare LF', ->
      h = parse_headers 'Content-Type:text/plain\nX-Foo:  bar  \n'
      assert.equal 'text/plain', h['content-type']
      assert.equal 'bar', h['x-foo']

    it 'keeps duplicates', ->
      h = parse_headers 'Set-Cookie: a=1\r\nSet-Cookie: b=2\r\n'
      assert.same {'a=1', 'b=2'}, h\all('set-cookie')

    it 'joins obs-fold continuation lines', ->
      h = parse_headers 'X-Long: first\r\n  second\r\nX-Other: 1\r\n'
      assert.equal 'first second', h['x-long']
      assert.equal '1', h['x-other']

    it 'accepts an empty value', ->
      assert.equal '', parse_headers('X-Empty:\r\n')['x-empty']

    it 'refuses a block starting with a continuation', ->
      h, err = parse_headers '  orphaned\r\n'
      assert.is_nil h
      assert.matches 'continuation', err

    it 'refuses an invalid header name', ->
      for block in *{'X Foo: bar\r\n', ': bar\r\n'}
        h, err = parse_headers block
        assert.is_nil h
        assert.matches 'invalid HTTP header name', err

    it 'refuses a line with no colon', ->
      h, err = parse_headers 'nonsense\r\n'
      assert.is_nil h
      assert.matches 'malformed HTTP header line', err

  describe 'parse_head(data)', ->
    it 'returns the head and the remaining body', ->
      head, rest = parse_head 'HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nhello'
      assert.equal 200, head.status
      assert.equal '5', head.headers['content-length']
      assert.equal 'hello', rest

    it 'signals incompleteness with nil, nil rather than an error', ->
      head, err = parse_head 'HTTP/1.1 200 OK\r\nContent-Len'
      assert.is_nil head
      assert.is_nil err

    it 'accepts a bare LF terminated head', ->
      head, rest = parse_head 'HTTP/1.1 200 OK\nX-Foo: 1\n\nbody'
      assert.equal 200, head.status
      assert.equal 'body', rest

    it 'skips an unsolicited 1xx interim response', ->
      head, rest = parse_head 'HTTP/1.1 100 Continue\r\n\r\nHTTP/1.1 200 OK\r\nX-Foo: 1\r\n\r\nbody'
      assert.equal 200, head.status
      assert.equal '1', head.headers['x-foo']
      assert.equal 'body', rest

    it 'skips several interim responses', ->
      head = parse_head 'HTTP/1.1 100 Continue\r\n\r\nHTTP/1.1 103 Early Hints\r\nLink: x\r\n\r\nHTTP/1.1 201 Created\r\n\r\n'
      assert.equal 201, head.status

    it 'waits for more data when only an interim response has arrived', ->
      head, err = parse_head 'HTTP/1.1 100 Continue\r\n\r\n'
      assert.is_nil head
      assert.is_nil err

    it 'refuses a head larger than the cap', ->
      head, err = parse_head 'HTTP/1.1 200 OK\r\nX: ' .. string.rep('a', hm.MAX_HEAD_SIZE)
      assert.is_nil head
      assert.matches 'exceeds', err

    it 'propagates a malformed status line', ->
      head, err = parse_head 'garbage\r\n\r\n'
      assert.is_nil head
      assert.matches 'malformed HTTP status line', err

  describe 'body_framing(status, method, headers)', ->
    framing_for = (status, method, header_table) ->
      body_framing status, method, create(header_table or {})

    it 'reports none for HEAD, 204 and 304', ->
      assert.equal 'none', framing_for(200, 'HEAD', {'Content-Length': '10'})
      assert.equal 'none', framing_for(204, 'GET')
      assert.equal 'none', framing_for(304, 'GET', {'Content-Length': '10'})

    it 'reports a length when Content-Length is present', ->
      assert.same {length: 42}, framing_for(200, 'GET', {'Content-Length': '42'})

    it 'accepts a zero Content-Length', ->
      assert.same {length: 0}, framing_for(200, 'GET', {'Content-Length': '0'})

    it 'reports chunked when Transfer-Encoding ends in chunked', ->
      assert.equal 'chunked', framing_for(200, 'GET', {'Transfer-Encoding': 'chunked'})

    it 'reports eof when neither is present', ->
      assert.equal 'eof', framing_for(200, 'GET')

    it 'refuses Transfer-Encoding and Content-Length together', ->
      framing, err = framing_for 200, 'GET',
        {'Transfer-Encoding': 'chunked', 'Content-Length': '5'}
      assert.is_nil framing
      assert.matches 'both Transfer%-Encoding and Content%-Length', err

    it 'refuses a Transfer-Encoding that is not chunked', ->
      framing, err = framing_for 200, 'GET', {'Transfer-Encoding': 'gzip'}
      assert.is_nil framing
      assert.matches 'unsupported Transfer%-Encoding', err

    it 'refuses a non-numeric Content-Length', ->
      framing, err = framing_for 200, 'GET', {'Content-Length': 'nope'}
      assert.is_nil framing
      assert.matches 'malformed Content%-Length', err

    it 'refuses conflicting Content-Length values', ->
      h = create!
      h\add 'Content-Length', '5'
      h\add 'Content-Length', '6'
      framing, err = body_framing 200, 'GET', h
      assert.is_nil framing
      assert.matches 'conflicting Content%-Length', err

    it 'accepts repeated but identical Content-Length values', ->
      h = create!
      h\add 'Content-Length', '5'
      h\add 'Content-Length', '5'
      assert.same {length: 5}, body_framing(200, 'GET', h)

  describe 'check_content_encoding(headers)', ->
    it 'accepts absent or identity encoding', ->
      assert.is_true check_content_encoding(create!)
      assert.is_true check_content_encoding(create {'Content-Encoding': 'identity'})

    it 'refuses gzip', ->
      ok, err = check_content_encoding create {'Content-Encoding': 'gzip'}
      assert.is_nil ok
      assert.matches 'unsupported Content%-Encoding', err

  describe 'ChunkedDecoder', ->
    it 'decodes a single chunk', ->
      d = ChunkedDecoder!
      body, done = d\feed '5\r\nhello\r\n0\r\n\r\n'
      assert.equal 'hello', body
      assert.is_true done

    it 'decodes several chunks', ->
      d = ChunkedDecoder!
      body, done = d\feed '3\r\nabc\r\n2\r\nde\r\n0\r\n\r\n'
      assert.equal 'abcde', body
      assert.is_true done

    it 'decodes an empty body', ->
      d = ChunkedDecoder!
      body, done = d\feed '0\r\n\r\n'
      assert.equal '', body
      assert.is_true done

    it 'ignores chunk extensions', ->
      d = ChunkedDecoder!
      body, done = d\feed '5;name=value\r\nhello\r\n0\r\n\r\n'
      assert.equal 'hello', body
      assert.is_true done

    it 'handles an uppercase hex size', ->
      d = ChunkedDecoder!
      body = d\feed 'A\r\n0123456789\r\n0\r\n\r\n'
      assert.equal '0123456789', body

    it 'collects trailers', ->
      d = ChunkedDecoder!
      body, done = d\feed '3\r\nabc\r\n0\r\nX-Checksum: deadbeef\r\n\r\n'
      assert.equal 'abc', body
      assert.is_true done
      assert.same {'X-Checksum: deadbeef'}, d.trailers

    it 'is not done until the terminating chunk arrives', ->
      d = ChunkedDecoder!
      body, done = d\feed '3\r\nabc\r\n'
      assert.equal 'abc', body
      assert.is_false done

    it 'accumulates across feeds split at an arbitrary point', ->
      d = ChunkedDecoder!
      first = d\feed '3\r\nab'
      second = d\feed 'c\r\n0\r\n\r\n'
      assert.equal 'abc', first .. second

    it 'handles a split between the chunk data and its CRLF', ->
      d = ChunkedDecoder!
      a = d\feed '3\r\nabc\r'
      b, done = d\feed '\n0\r\n\r\n'
      assert.equal 'abc', a .. b
      assert.is_true done

    it 'handles a split inside the size line', ->
      -- '10' is hex, so the chunk is 16 bytes long
      d = ChunkedDecoder!
      a = d\feed '1'
      b = d\feed '0\r\n0123456789abcdef\r\n0\r\n\r\n'
      assert.equal '0123456789abcdef', a .. b

    -- the decisive test: byte-at-a-time must equal a single feed
    it 'produces identical output fed one byte at a time', ->
      payload = '5;ext=1\r\nhello\r\n1\r\n \r\n6\r\nworld!\r\n0\r\nX-T: 1\r\n\r\n'
      whole = ChunkedDecoder!\feed payload
      piecemeal, decoder = decode_bytewise payload

      assert.equal 'hello world!', whole
      assert.equal whole, piecemeal
      assert.is_true decoder.done
      assert.same {'X-T: 1'}, decoder.trailers

    it 'handles a large body fed one byte at a time', ->
      data = string.rep 'x', 300
      payload = "#{string.format '%x', #data}\r\n#{data}\r\n0\r\n\r\n"
      piecemeal = decode_bytewise payload
      assert.equal data, piecemeal

    it 'reports leftover data after the terminating chunk', ->
      d = ChunkedDecoder!
      d\feed '3\r\nabc\r\n0\r\n\r\nextra'
      assert.equal 'extra', d\leftover!

    it 'has no leftover before completion', ->
      d = ChunkedDecoder!
      d\feed '3\r\nab'
      assert.equal '', d\leftover!

    it 'raises on a bad chunk size', ->
      assert.raises 'bad chunk size', -> ChunkedDecoder!\feed 'zz\r\nabc\r\n'

    it 'raises when the CRLF after a chunk is missing', ->
      assert.raises 'missing CRLF after chunk', -> ChunkedDecoder!\feed '3\r\nabcXX'

    it 'raises on an oversized chunk size line', ->
      assert.raises 'chunk size line exceeds', ->
        ChunkedDecoder!\feed string.rep('0', hm.MAX_CHUNK_LINE + 1)
