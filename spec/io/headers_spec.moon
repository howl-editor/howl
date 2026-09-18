-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

headers = howl.io.headers
{:create} = headers

describe 'headers', ->
  describe 'create(initial)', ->
    it 'looks names up case-insensitively', ->
      h = create!
      h\set 'Content-Type', 'application/json'
      assert.equal 'application/json', h['content-type']
      assert.equal 'application/json', h['Content-Type']
      assert.equal 'application/json', h['CONTENT-TYPE']
      assert.equal 'application/json', h\get('cOnTeNt-TyPe')

    it 'returns nil for an absent header', ->
      assert.is_nil create!['x-missing']

    it 'populates from an initial table', ->
      h = create Accept: 'text/plain'
      assert.equal 'text/plain', h['accept']

    it 'assignment sets, and nil removes', ->
      h = create!
      h['X-Foo'] = 'bar'
      assert.equal 'bar', h['x-foo']
      h['X-Foo'] = nil
      assert.is_nil h['x-foo']
      assert.equal 0, h\count!

    it 'set replaces every previous value for the name', ->
      h = create!
      h\add 'X-Foo', 'one'
      h\add 'X-Foo', 'two'
      h\set 'x-foo', 'three'
      assert.same {'three'}, h\all('X-Foo')
      assert.equal 1, h\count!

  describe 'repeated headers', ->
    it 'all() returns every value in order', ->
      h = create!
      h\add 'Set-Cookie', 'a=1'
      h\add 'Set-Cookie', 'b=2'
      assert.same {'a=1', 'b=2'}, h\all('set-cookie')

    it 'scalar lookup returns the last value', ->
      h = create!
      h\add 'X-Foo', 'first'
      h\add 'X-Foo', 'last'
      assert.equal 'last', h['x-foo']

    it 'all() returns an empty table for an absent header', ->
      assert.same {}, create!\all('nope')

    it 'does not comma-join Set-Cookie', ->
      h = create!
      h\add 'Set-Cookie', 'a=1'
      h\add 'Set-Cookie', 'b=2'
      assert.equal 2, h\count!

  describe 'each()', ->
    it 'yields every line, duplicates included, in wire order', ->
      h = create!
      h\add 'B', '2'
      h\add 'A', '1'
      h\add 'B', '3'
      collected = {}
      for name, value in h\each!
        collected[#collected + 1] = "#{name}: #{value}"

      assert.same {'B: 2', 'A: 1', 'B: 3'}, collected

    it 'preserves the casing the caller used', ->
      h = create!
      h\set 'CoNtEnT-tYpE', 'text/plain'
      names = [name for name in h\each!]
      assert.same {'CoNtEnT-tYpE'}, names

  describe 'to_table()', ->
    it 'returns a lower-cased snapshot', ->
      h = create!
      h\set 'Content-Length', '12'
      assert.same {'content-length': '12'}, h\to_table!

  describe 'has() and count()', ->
    it 'reports presence case-insensitively', ->
      h = create Accept: 'x'
      assert.is_true h\has('ACCEPT')
      assert.is_false h\has('accepts')

  describe 'is_valid_name(name)', ->
    it 'accepts RFC tokens', ->
      for name in *{'Content-Type', 'X-Foo', 'a', 'X_Y', "X'1", 'X.Y', 'X~Z'}
        assert.is_true headers.is_valid_name(name), "expected #{name} to be valid"

    it 'rejects anything that could inject a header', ->
      for name in *{'X-Foo:', 'X Foo', 'X\r\nEvil', 'X\nEvil', '', 'X\0Y'}
        assert.is_false headers.is_valid_name(name), "expected #{name} to be rejected"

    it 'rejects non-strings', ->
      assert.is_false headers.is_valid_name(nil)
      assert.is_false headers.is_valid_name(12)

  describe 'is_valid_value(value)', ->
    it 'accepts ordinary values', ->
      for value in *{'text/plain', 'a b c', 'Bearer xyz.123', ''}
        assert.is_true headers.is_valid_value(value), "expected '#{value}' to be valid"

    it 'rejects CR, LF and NUL', ->
      for value in *{'a\r\nEvil: 1', 'a\nEvil: 1', 'a\rb', 'a\0b'}
        assert.is_false headers.is_valid_value(value)

    it 'rejects leading or trailing whitespace', ->
      assert.is_false headers.is_valid_value(' leading')
      assert.is_false headers.is_valid_value('trailing ')

  describe 'validate_name() / validate_value()', ->
    it 'returns the input when valid', ->
      assert.equal 'X-Foo', headers.validate_name('X-Foo')
      assert.equal 'bar', headers.validate_value('X-Foo', 'bar')

    it 'raises naming the offender', ->
      assert.raises 'invalid HTTP header name', -> headers.validate_name 'X Foo'
      assert.raises "invalid value for HTTP header 'X%-Foo'", ->
        headers.validate_value 'X-Foo', 'a\r\nEvil: 1'
