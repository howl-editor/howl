{:json} = howl.util

describe 'json', ->
  describe 'encode(value)', ->
    it 'encodes scalars', ->
      assert.equal '"foo"', json.encode 'foo'
      assert.equal 'true', json.encode true
      assert.equal 'false', json.encode false
      assert.equal 'null', json.encode nil

    it 'encodes integers without decimals, and floats with the digits needed to read them back', ->
      assert.equal '3', json.encode 3
      assert.equal '-12', json.encode(-12)
      assert.equal '1728000000', json.encode 1728000000
      assert.equal '0.1', json.encode 0.1
      assert.equal '2.5', json.encode 2.5
      assert.equal 1728000000.123456, json.decode json.encode(1728000000.123456)
      assert.equal 1 / 3, json.decode json.encode(1 / 3)

    it 'escapes quotes, backslashes and control characters, keeping other text as is', ->
      assert.equal [["a\"b\\c\nd\te\u0001"]], json.encode 'a"b\\c\nd\te\1'
      assert.equal '"åäö ∀ 😀"', json.encode 'åäö ∀ 😀'

    it 'encodes lists as arrays, and other tables as objects with sorted keys', ->
      assert.equal '[\n  1,\n  "two"\n]', json.encode {1, 'two'}
      assert.equal '{\n  "a": 1,\n  "b": 2,\n  "c": 3\n}', json.encode {c: 3, a: 1, b: 2}

    it 'indents nested values by two spaces per level', ->
      expected = '{\n  "list": [\n    {\n      "x": true\n    }\n  ],\n  "obj": {\n    "y": "z"\n  }\n}'
      assert.equal expected, json.encode {list: {{x: true}}, obj: {y: 'z'}}

    it 'encodes empty tables as {}', ->
      assert.equal '{}', json.encode {}
      assert.equal '{\n  "a": {}\n}', json.encode {a: {}}

    it 'raises an error for keys that are not strings, outside of lists', ->
      assert.raises 'number key', -> json.encode {1, 2, x: 3}
      assert.raises 'number key', -> json.encode {[2]: 'x'}
      assert.raises 'boolean key', -> json.encode {[true]: 'x'}

    it 'raises an error for values that JSON can not represent', ->
      assert.raises 'function', -> json.encode {f: ->}
      assert.raises 'nan', -> json.encode 0 / 0
      assert.raises 'inf', -> json.encode math.huge

    it 'raises an error for tables containing themselves', ->
      t = {}
      t.t = t
      assert.raises 'containing itself', -> json.encode t

    it 'allows the same table more than once', ->
      shared = {1}
      assert.same {a: {1}, b: {1}}, json.decode json.encode({a: shared, b: shared})

  describe 'decode(text)', ->
    it 'returns the value of the text', ->
      assert.same {a: {1, 'två', true}, b: {c: 1.5}}, json.decode '{"a": [1, "två", true], "b": {"c": 1.5}}'
      assert.equal 'x', json.decode '"x"'

    it 'decodes unicode escapes', ->
      assert.equal 'å😀', json.decode '"\\u00e5\\ud83d\\ude00"'

    it 'decodes null as nil', ->
      assert.same {a: 1}, json.decode '{"a": 1, "b": null}'

    it 'reads back what encode gives', ->
      value = {name: 'ö', list: {1, 2.5, 'x'}, nested: {flag: false, empty: {}}}
      assert.same value, json.decode json.encode(value)

    it 'raises an error with the position for malformed text', ->
      assert.raises '^parse error at %d+: invalid value', -> json.decode '{"a": }'
      assert.raises '^parse error', -> json.decode ''
      assert.raises '^parse error', -> json.decode '{"a": 1} x'

    it 'raises an error for anything but a string', ->
      assert.raises 'expected a string', -> json.decode nil
