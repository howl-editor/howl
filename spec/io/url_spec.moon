-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

url = howl.io.url

describe 'url', ->
  describe 'parse(s)', ->
    it 'parses the parts of a full URL', ->
      u = url.parse 'https://user@example.com:8443/a/b?q=1#frag'
      assert.equal 'https', u.scheme
      assert.equal 'user', u.userinfo
      assert.equal 'example.com', u.host
      assert.equal 8443, u.port
      assert.equal '/a/b', u.path
      assert.equal 'q=1', u.query
      assert.equal 'frag', u.fragment

    it 'defaults the port from the scheme', ->
      assert.equal 80, url.parse('http://example.com/').port
      assert.equal 443, url.parse('https://example.com/').port
      assert.equal 443, url.parse('https://example.com/').default_port

    it 'defaults an empty path to /', ->
      assert.equal '/', url.parse('http://example.com').path

    it 'lower-cases the scheme', ->
      assert.equal 'https', url.parse('HTTPS://example.com/').scheme

    it 'drops the fragment from .url, since it is never sent to a server', ->
      assert.equal 'https://example.com/a?q=1', url.parse('https://example.com/a?q=1#frag').url

    it 'keeps userinfo as given', ->
      -- GUri treats 'user:pass' as opaque userinfo rather than rejecting it, so
      -- refusing credentials-in-URL is the HTTP layer's job, not this one
      assert.equal 'user:pass', url.parse('https://user:pass@example.com/').userinfo

  describe 'the authority field', ->
    it 'omits the port when it is the scheme default', ->
      assert.equal 'example.com', url.parse('http://example.com:80/').authority
      assert.equal 'example.com', url.parse('https://example.com/').authority

    it 'includes a non-default port', ->
      assert.equal 'example.com:8443', url.parse('https://example.com:8443/').authority

    it 're-brackets an IPv6 host', ->
      u = url.parse 'http://[::1]:8080/x'
      assert.equal '::1', u.host
      assert.equal '[::1]:8080', u.authority

    it 're-brackets an IPv6 host on the default port', ->
      assert.equal '[::1]', url.parse('http://[::1]/x').authority

  describe 'the request_target field', ->
    it 'is the path when there is no query', ->
      assert.equal '/a/b', url.parse('http://example.com/a/b').request_target

    it 'includes the query', ->
      assert.equal '/a/b?q=1&r=2', url.parse('http://example.com/a/b?q=1&r=2').request_target

    it 'is / for a bare host', ->
      assert.equal '/', url.parse('http://example.com').request_target

    it 'excludes the fragment', ->
      assert.equal '/a', url.parse('http://example.com/a#frag').request_target

  describe 'parse() failures', ->
    it 'rejects a relative URL', ->
      u, err = url.parse 'example.com/x'
      assert.is_nil u
      assert.matches 'invalid URL', err

    it 'rejects an empty string and a non-string', ->
      assert.is_nil (url.parse '')
      assert.is_nil (url.parse nil)
      assert.is_nil (url.parse 42)

    it 'rejects a malformed IPv6 host', ->
      u, err = url.parse 'http://[bad/x'
      assert.is_nil u
      assert.matches 'invalid URL', err

    it 'rejects a URL with no host', ->
      assert.is_nil (url.parse 'file:///tmp/x')

  describe 'resolve(base, ref)', ->
    base = 'https://example.com/a/b/c?old=1'

    it 'resolves a relative path', ->
      assert.equal 'https://example.com/a/b/d', url.resolve(base, 'd').url

    it 'resolves a parent reference', ->
      assert.equal 'https://example.com/a/d', url.resolve(base, '../d').url

    it 'resolves an absolute path', ->
      assert.equal 'https://example.com/d', url.resolve(base, '/d').url

    it 'resolves a scheme-relative reference', ->
      u = url.resolve base, '//other.com/x'
      assert.equal 'other.com', u.host
      assert.equal 'https', u.scheme

    it 'resolves a query-only reference', ->
      assert.equal 'q=2', url.resolve(base, '?q=2').query

    it 'passes an absolute reference through', ->
      assert.equal 'http://other.com/x', url.resolve(base, 'http://other.com/x').url

    it 'accepts a parsed table as the base', ->
      assert.equal 'https://example.com/a/b/d', url.resolve(url.parse(base), 'd').url

    it 'reports a malformed reference', ->
      u, err = url.resolve base, 'http://[bad'
      assert.is_nil u
      assert.matches 'invalid URL reference', err

  describe 'escape(s) / unescape(s)', ->
    it 'percent-encodes reserved characters', ->
      assert.equal 'a%2Fb%20c%26d', url.escape('a/b c&d')

    it 'honours an allowed-character set', ->
      assert.equal 'a/b%20c', url.escape('a/b c', '/')

    it 'round-trips', ->
      for s in *{'a b', 'a/b&c=d', 'plain', 'åäö'}
        assert.equal s, url.unescape(url.escape(s))

  describe 'build_query(params)', ->
    it 'encodes keys and values', ->
      assert.equal 'a=1&b=x%20y', url.build_query {a: 1, b: 'x y'}

    it 'sorts keys so output is deterministic', ->
      assert.equal 'a=1&b=2&c=3', url.build_query {c: 3, a: 1, b: 2}

    it 'expands a list value into repeated keys', ->
      assert.equal 'tag=one&tag=two', url.build_query {tag: {'one', 'two'}}

    it 'returns an empty string for no params', ->
      assert.equal '', url.build_query {}

  describe 'bracket(host)', ->
    it 'brackets only an IPv6 literal', ->
      assert.equal '[::1]', url.bracket('::1')
      assert.equal 'example.com', url.bracket('example.com')
