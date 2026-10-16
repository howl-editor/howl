import mode, bundle from howl
append = table.insert

describe 'Howlscript lexer', ->
  local lexer

  setup ->
    bundle.load_by_name 'lua'
    bundle.load_by_name 'c'
    bundle.load_by_name 'howlscript'
    lexer = mode.by_name('howlscript').lexer

  teardown ->
    bundle.unload 'howlscript'
    bundle.unload 'c'
    bundle.unload 'lua'

  result = (text, ...) ->
    styles = {k,true for k in *{...}}
    tokens = lexer text
    parts = {}

    for i = 1, #tokens, 3
      style = tokens[i + 1]
      part = text\sub tokens[i], tokens[i + 2] - 1
      append(parts, part) if styles[tostring style]

    parts

  it 'handles keywords', ->
    assert.same { 'if', 'then', 'elseif', 'else', 'unless', 'continue' }, result 'if foo then ifi elseif else unless continue', 'keyword'

  it 'does not take field names for keywords', ->
    assert.same {}, result 't.then, obj:if(), @unless', 'keyword'
    assert.same { 't', 'then' }, result 't.then', 'identifier'

  it 'handles comments', ->
    assert.same { '--wat' }, result '  --wat', 'comment'

  describe '--', ->
    it 'is the decrement operator when touching a name or ]', ->
      assert.same { '--' }, result 'x--', 'operator'
      assert.same { '[', ']', '--' }, result 't[1]--', 'operator'
      assert.same {}, result 'x--', 'comment'

    it 'starts a comment otherwise', ->
      assert.same { '-- c' }, result 'x -- c', 'comment'
      assert.same {}, result 'x -- c', 'operator'

  it 'handles single quoted strings', ->
    assert.same { "'str'" }, result " 'str' ", 'string'

  it 'handles double quoted strings', ->
    assert.same { '"', 'str"' }, result ' "str" ', 'string'

  it 'handles long strings, which have no levels', ->
    assert.same { '[[\nfoo\n]]' }, result ' [[\nfoo\n]] ', 'string'
    assert.same { '[[ a ]]' }, result '[[ a ]] b ]]', 'string'
    assert.same { '[==[' }, result '[==[ a ]==]', 'error'

  it 'handles backslash escapes in strings', ->
    assert.same { "'str\\''", '"', 'str\\""' }, result [['str\'' x "str\""]], 'string'

  it 'handles numbers', ->
    assert.same { '12', '0xfe', '3.1416', '314.16e-2', '0xA23p-4', '.2', '10ULL' },
      result '12 0xfe 3.1416 314.16e-2 0xA23p-4 .2 10ULL', 'number'

  it 'lexes ordinary names as identifier', ->
    assert.same { 'hi', '_var', 'take2' }, result "hi _var take2", 'identifier'

  it 'lexes import and from as identifiers, as Howlscript has no import', ->
    assert.same { 'import', 'from' }, result "import from", 'identifier'
    assert.same {}, result "import from", 'keyword'

  it 'handles operators', ->
    assert.same { '+', ',', '!=', '~=', '{', '(', ')', '/', '}', ',', 'or=', '->', '=>' },
      result '1+2, != ~= {(a)/x}, or= -> =>', 'operator'

  it 'handles members', ->
    assert.same { '@foo', '@@bar', 'self.foo', '@' }, result " @foo @@bar self.foo @", 'member'

  it 'lexes true, false and nil as special, except as fields', ->
    assert.same { 'true', 'false', 'nil' }, result "if true then false else nil", 'special'
    assert.same {}, result 'assert.true(x)', 'special'

  it 'lexes capitalized identifiers as type', ->
    assert.same { 'Foo' }, result "Foo", 'type'

  it 'lexes class definition names as type_def', ->
    assert.same { 'Foo' }, result "class Foo extends Bar", 'type_def'

  describe 'property declarations', ->
    it 'lex property as a keyword and the name as a key', ->
      assert.same { 'property', 'size' }, result "  property size => 1", 'keyword', 'key'
      assert.same { 'property', 'text', 'get:' }, result "  property text\n    get: => 1", 'keyword', 'key'

    it 'leave other uses of property alone', ->
      assert.same {}, result "@property(x: 1)\nproperty = 1\nf(property, x)\nproperty x, y", 'keyword'

  describe 'keys', ->
    it 'are names, strings and :names followed by a colon and a space', ->
      assert.same { ':ref', 'plain:', "'string key':", 'end:' },
        result "{:ref, plain: true, 'string key': oh_yes, end: 1}", 'key'

    it 'include a key at the end of a line', ->
      assert.same { 'key:' }, result "{\n  key:\n    1\n}", 'key'

    it 'are not method calls', ->
      assert.same {}, result "obj:method(), 'str':upper(), f():g(), t[1]:h()", 'key'
      assert.same { 'obj', 'method', 'upper' }, result "obj:method(), 'str':upper()", 'identifier'

    it 'are not method calls in with blocks', ->
      assert.same {}, result '  :save()', 'key'

  it 'lexes Lua keywords used as names as error, but not as fields and keys', ->
    assert.same { 'function', 'end', 'goto', 'repeat', 'until' }, result "function() end, end_marker goto repeat until", 'error'
    assert.same {}, result "t.end, obj:end(), {end: 1}", 'error'

  it 'lexes \\, ! and ; as error', ->
    assert.same { '\\', '!', ';' }, result "obj\\m!; x != y", 'error'

  it 'lexes function definitions', ->
    assert.same { 'f', 'g', 'm' }, result "f = (a, b = 1) ->\ng = ->\nm = (@x, {:y}) =>", 'fdecl'

  it 'does sub-lexing within string interpolations', ->
    assert.same { '#', '{', '+', '}', '#', '{', '/', '}', ',' }, result '"#{x + y} +var+ #{z/0}", trailing', 'operator'

  it 'lexes ffi.cdef strings as C', ->
    text = 'ffi.cdef([[int x;]])'
    tokens = lexer text
    strings, sub_lexed = {}, {}
    for i = 1, #tokens, 3
      if type(tokens[i + 1]) == 'table'
        append sub_lexed, text\sub(tokens[i], tokens[i] + 5)
      elseif tokens[i + 1] == 'string'
        append strings, text\sub(tokens[i], tokens[i + 2] - 1)
    assert.same { '[[', ']]' }, strings
    assert.same { 'int x;' }, sub_lexed
