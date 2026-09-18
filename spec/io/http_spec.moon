-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

http = howl.io.http
{:File} = howl.io

describe 'http', ->
  local server

  before_each ->
    set_howl_loop!
    server = HttpServer!

  after_each ->
    server\stop! if server

  describe 'get()', ->
    it 'returns the body and status of a 200', (done) ->
      howl_async ->
        server\route '/hello', body: 'hi there'
        res = http.get server\url '/hello'
        assert.equal 200, res.status
        assert.equal 'OK', res.status_text
        assert.equal 'hi there', res.body
        assert.is_true res.ok
        done!

    it 'exposes headers case-insensitively', (done) ->
      howl_async ->
        server\route '/h', body: 'x', headers: {'Content-Type': 'text/plain; charset=utf-8'}
        res = http.get server\url '/h'
        assert.equal 'text/plain; charset=utf-8', res.headers['CONTENT-TYPE']
        assert.equal 'text/plain', res.content_type
        assert.equal 1, res.content_length
        done!

    it 'sends Host, User-Agent, Connection and Accept-Encoding', (done) ->
      howl_async ->
        server\route '/h', body: ''
        http.get server\url '/h'
        sent = server.requests[1].headers
        assert.equal "127.0.0.1:#{server.port}", sent.host
        assert.equal 'close', sent.connection
        assert.equal 'identity', sent['accept-encoding']
        assert.is_not_nil sent['user-agent']
        done!

    it 'sends caller headers and a custom user agent', (done) ->
      howl_async ->
        server\route '/h', body: ''
        http.get server\url('/h'), headers: {'X-Foo': 'bar'}, user_agent: 'Spec/1'
        sent = server.requests[1].headers
        assert.equal 'bar', sent['x-foo']
        assert.equal 'Spec/1', sent['user-agent']
        done!

    it 'appends a query', (done) ->
      howl_async ->
        server\route '/search', body: 'ok'
        res = http.get server\url('/search'), query: {q: 'a b', page: 2}
        assert.equal 200, res.status
        assert.equal '/search?page=2&q=a%20b', server.requests[1].target
        done!

    it 'returns a 404 as a response rather than raising', (done) ->
      howl_async ->
        res = http.get server\url '/nothing-here'
        assert.equal 404, res.status
        assert.is_false res.ok
        done!

    it 'raises on a non-2xx when expect_success is set', (done) ->
      howl_async ->
        assert.raises 'HTTP 404', ->
          http.get server\url('/nothing-here'), expect_success: true
        done!

    it 'raise_for_status() raises only for a non-2xx', (done) ->
      howl_async ->
        server\route '/ok', body: 'y'
        assert.has_no_error -> http.get(server\url '/ok')\raise_for_status!
        assert.raises 'HTTP 404', -> http.get(server\url '/nope')\raise_for_status!
        done!

  describe 'body framing', ->
    it 'reads a chunked body', (done) ->
      howl_async ->
        server\route '/c', chunked: {'ab', 'cd', 'ef'}
        res = http.get server\url '/c'
        assert.equal 'abcdef', res.body
        done!

    it 'reads a chunked body with trailers', (done) ->
      howl_async ->
        server\route '/c', chunked: {'ab'}, trailers: {'X-Sum: 1'}
        assert.equal 'ab', http.get(server\url '/c').body
        done!

    it 'reads a body delimited only by the connection closing', (done) ->
      howl_async ->
        server\route '/eof', body: 'no length here', no_content_length: true
        assert.equal 'no length here', http.get(server\url '/eof').body
        done!

    it 'reads an empty body', (done) ->
      howl_async ->
        server\route '/empty', body: ''
        assert.equal '', http.get(server\url '/empty').body
        done!

    it 'returns no body for a 204', (done) ->
      howl_async ->
        server\route '/204', status: 204, reason: 'No Content', body: ''
        res = http.get server\url '/204'
        assert.equal 204, res.status
        assert.equal '', res.body
        done!

    it 'refuses a response that is both chunked and length-delimited', (done) ->
      howl_async ->
        server\raw '/smuggle',
          'HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\nContent-Length: 5\r\n\r\n0\r\n\r\n'
        assert.raises 'both Transfer%-Encoding and Content%-Length', ->
          http.get server\url '/smuggle'
        done!

    it 'refuses a compressed response', (done) ->
      howl_async ->
        server\route '/gz', body: 'junk', headers: {'Content-Encoding': 'gzip'}
        assert.raises 'unsupported Content%-Encoding', -> http.get server\url '/gz'
        done!

    it 'raises on a malformed status line', (done) ->
      howl_async ->
        server\raw '/bad', 'NOT HTTP AT ALL\r\n\r\n'
        assert.raises 'malformed HTTP status line', -> http.get server\url '/bad'
        done!

    it 'raises when the connection closes mid-body', (done) ->
      howl_async ->
        server\raw '/short', 'HTTP/1.1 200 OK\r\nContent-Length: 100\r\n\r\ntoo short'
        assert.raises 'connection closed after', -> http.get server\url '/short'
        done!

    it 'raises when the connection closes before the headers', (done) ->
      howl_async ->
        server\route '/hangup', close_early: true
        assert.raises 'connection closed before', -> http.get server\url '/hangup'
        done!

  describe 'head()', ->
    it 'gets headers without a body', (done) ->
      howl_async ->
        server\route '/h', body: 'would be a body'
        res = http.head server\url '/h'
        assert.equal 200, res.status
        assert.equal '', res.body
        assert.equal 'HEAD', server.requests[1].method
        done!

  describe 'post()', ->
    it 'sends a string body with a Content-Length', (done) ->
      howl_async ->
        server\route '/p', body: 'got it'
        res = http.post server\url('/p'), 'payload'
        assert.equal 'got it', res.body
        request = server.requests[1]
        assert.equal 'POST', request.method
        assert.equal 'payload', request.body
        assert.equal '7', request.headers['content-length']
        done!

    it 'encodes a json body and sets the content type', (done) ->
      howl_async ->
        server\route '/p', body: '{}'
        http.post server\url('/p'), json: {name: 'howl'}
        request = server.requests[1]
        assert.equal 'application/json', request.headers['content-type']
        assert.equal '{"name":"howl"}', request.body
        done!

    it 'encodes a form body and sets the content type', (done) ->
      howl_async ->
        server\route '/p', body: 'ok'
        http.post server\url('/p'), form: {a: 1, b: 'x y'}
        request = server.requests[1]
        assert.equal 'application/x-www-form-urlencoded', request.headers['content-type']
        assert.equal 'a=1&b=x%20y', request.body
        done!

    it 'refuses more than one body form', (done) ->
      howl_async ->
        assert.raises 'at most one of body, json or form', ->
          http.post server\url('/p'), {body: 'a', json: {}}
        done!

  describe 'res\\json()', ->
    it 'decodes a JSON body', (done) ->
      howl_async ->
        server\route '/j', body: '{"a":[1,2],"b":"x"}'
        decoded = http.get(server\url '/j')\json!
        assert.same {1, 2}, decoded.a
        assert.equal 'x', decoded.b
        done!

    it 'raises on a body that is not JSON', (done) ->
      howl_async ->
        server\route '/j', body: 'not json'
        assert.raises 'not valid JSON', -> http.get(server\url '/j')\json!
        done!

  describe 'redirects', ->
    it 'follows one and records it', (done) ->
      howl_async ->
        server\route '/start', status: 302, reason: 'Found', headers: {Location: '/end'}, body: ''
        server\route '/end', body: 'arrived'
        res = http.get server\url '/start'
        assert.equal 200, res.status
        assert.equal 'arrived', res.body
        assert.equal server\url('/end'), res.url
        assert.equal server\url('/start'), res.request_url
        assert.same {server\url '/start'}, res.redirects
        done!

    it 'follows a chain', (done) ->
      howl_async ->
        server\route '/a', status: 302, headers: {Location: '/b'}, body: ''
        server\route '/b', status: 302, headers: {Location: '/c'}, body: ''
        server\route '/c', body: 'end'
        res = http.get server\url '/a'
        assert.equal 'end', res.body
        assert.equal 2, #res.redirects
        done!

    it 'resolves a relative Location', (done) ->
      howl_async ->
        server\route '/dir/one', status: 302, headers: {Location: 'two'}, body: ''
        server\route '/dir/two', body: 'relative ok'
        assert.equal 'relative ok', http.get(server\url '/dir/one').body
        done!

    it 'does not follow when max_redirects is 0', (done) ->
      howl_async ->
        server\route '/start', status: 302, headers: {Location: '/end'}, body: ''
        res = http.get server\url('/start'), max_redirects: 0
        assert.equal 302, res.status
        done!

    it 'raises when the hop limit is exceeded', (done) ->
      howl_async ->
        server\route '/loop', status: 302, headers: {Location: '/loop'}, body: ''
        assert.raises 'too many redirects', ->
          http.get server\url('/loop'), max_redirects: 2
        done!

    it 'turns a 303 into a GET and drops the body', (done) ->
      howl_async ->
        server\route '/post-here', status: 303, headers: {Location: '/done'}, body: ''
        server\route '/done', body: 'ok'
        http.post server\url('/post-here'), 'payload'
        assert.equal 'POST', server.requests[1].method
        assert.equal 'GET', server.requests[2].method
        assert.is_nil server.requests[2].headers['content-length']
        done!

    it 'turns a 302 on a POST into a GET', (done) ->
      howl_async ->
        server\route '/p', status: 302, headers: {Location: '/done'}, body: ''
        server\route '/done', body: 'ok'
        http.post server\url('/p'), 'payload'
        assert.equal 'GET', server.requests[2].method
        done!

    it 'keeps the method and body for a 307', (done) ->
      howl_async ->
        server\route '/p', status: 307, headers: {Location: '/done'}, body: ''
        server\route '/done', body: 'ok'
        http.post server\url('/p'), 'payload'
        assert.equal 'POST', server.requests[2].method
        assert.equal 'payload', server.requests[2].body
        done!

    it 'keeps Authorization on a same-origin redirect', (done) ->
      howl_async ->
        server\route '/a', status: 302, headers: {Location: '/b'}, body: ''
        server\route '/b', body: 'ok'
        http.get server\url('/a'), headers: {Authorization: 'Bearer secret'}
        assert.equal 'Bearer secret', server.requests[2].headers.authorization
        done!

    it 'refuses a redirect to a non-http scheme', (done) ->
      howl_async ->
        server\route '/x', status: 302, headers: {Location: 'ftp://example.com/'}, body: ''
        assert.raises 'refusing to follow a redirect', -> http.get server\url '/x'
        done!

  describe 'limits and timeouts', ->
    it 'raises when the body exceeds max_size', (done) ->
      howl_async ->
        server\route '/big', body: string.rep('x', 500)
        assert.raises 'exceeds the 100 byte limit', ->
          http.get server\url('/big'), max_size: 100
        done!

    it 'raises when a chunked body exceeds max_size', (done) ->
      howl_async ->
        server\route '/big', chunked: {string.rep('x', 200), string.rep('y', 200)}
        assert.raises 'exceeds the 100 byte limit', ->
          http.get server\url('/big'), max_size: 100
        done!

    it 'allows a body up to max_size', (done) ->
      howl_async ->
        server\route '/fits', body: string.rep('x', 50)
        assert.equal 50, #http.get(server\url('/fits'), max_size: 50).body
        done!

    it 'times out a slow response', (done) ->
      settimeout 5
      howl_async ->
        server\route '/slow', body: 'too late', delay: 2
        assert.raises 'timed out', -> http.get server\url('/slow'), timeout: 0.3
        done!

    it 'reports progress', (done) ->
      howl_async ->
        server\route '/p', body: string.rep('x', 120)
        seen = {}
        http.get server\url('/p'), on_progress: (received, total) ->
          seen[#seen + 1] = received

        assert.is_true #seen > 0
        assert.equal 120, seen[#seen]
        done!

  describe 'request validation', ->
    it 'refuses a non-http scheme', (done) ->
      howl_async ->
        assert.raises 'only supports http and https', -> http.get 'ftp://example.com/'
        done!

    it 'refuses credentials in the URL', (done) ->
      howl_async ->
        assert.raises 'credentials in a URL are not sent', ->
          http.get 'http://user:pw@example.com/'
        done!

    it 'refuses a header value containing CRLF', (done) ->
      howl_async ->
        assert.raises 'invalid value for HTTP header', ->
          http.get server\url('/x'), headers: {'X-Foo': 'a\r\nEvil: 1'}
        done!

    it 'refuses to override a reserved header', (done) ->
      howl_async ->
        assert.raises 'cannot be overridden', ->
          http.get server\url('/x'), headers: {Host: 'evil.example.com'}
        done!

    it 'refuses an invalid URL', (done) ->
      howl_async ->
        assert.raises 'invalid URL', -> http.get 'not a url'
        done!

    -- the "must be called from a coroutine" guard cannot be exercised here:
    -- busted already runs every example inside one

  describe 'download()', ->
    it 'streams a body to a file and leaves no .part behind', (done) ->
      howl_async ->
        with_tmpdir (dir) ->
          server\route '/f', body: 'file contents'
          target = dir\join 'out.txt'
          res = http.download server\url('/f'), target
          assert.equal 'file contents', target.contents
          assert.is_false File("#{target.path}.part").exists
          assert.equal 200, res.status
          assert.equal target.path, res.file.path
        done!

    it 'streams a chunked body', (done) ->
      howl_async ->
        with_tmpdir (dir) ->
          server\route '/f', chunked: {'one', 'two'}
          target = dir\join 'out.txt'
          http.download server\url('/f'), target
          assert.equal 'onetwo', target.contents
        done!

    it 'removes the partial file and raises on a non-2xx', (done) ->
      howl_async ->
        with_tmpdir (dir) ->
          target = dir\join 'out.txt'
          assert.raises 'HTTP 404', -> http.download server\url('/missing'), target
          assert.is_false target.exists
          assert.is_false File("#{target.path}.part").exists
        done!

    it 'reports progress while downloading', (done) ->
      howl_async ->
        with_tmpdir (dir) ->
          server\route '/f', body: string.rep('z', 90)
          received = 0
          http.download server\url('/f'), dir\join('out.txt'), on_progress: (n) -> received = n
          assert.equal 90, received
        done!
