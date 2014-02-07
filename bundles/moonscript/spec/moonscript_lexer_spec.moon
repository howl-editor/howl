import mode, bundle from howl

describe 'Moonscript lexer', ->
  local lexer

  setup ->
    bundle.load_by_name 'lua'
    bundle.load_by_name 'moonscript'
    lexer = mode.by_name('moonscript').lexer

  teardown ->
    bundle.unload 'moonscript'
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

  it 'handles #keywords', ->
    assert.same { 'if', 'then' }, result 'if foo then ifi fif', 'keyword'

  it 'handles #comments', ->
    assert.same { '--wat' }, result '  --wat', 'comment'

  it 'handles single quoted strings', ->
    assert.same { "'str'" }, result " 'str' ", 'string'

  it 'handles double quoted strings', ->
    assert.same { '"', 'str"' }, result ' "str" ', 'string'

  it 'handles long strings', ->
    assert.same { '[[\nfoo\n]]' }, result ' [[\nfoo\n]] ', 'string'

  it 'handles backslash escapes in strings', ->
    assert.same { "'str\\''", '"', 'str\\""' }, result [['str\'' x "str\""]], 'string'

  it 'handles numbers', ->
    parts = result '12 0xfe 0Xaa 3.1416 314.16e-2 0.31416E1 0x0.1E 0xA23p-4 0X1.921FB54442D18P+1 .2', 'number'
    assert.same {
      '12',
      '0xfe',
      '0Xaa',
      '3.1416',
      '314.16e-2',
      '0.31416E1',
      '0x0.1E',
      '0xA23p-4',
      '0X1.921FB54442D18P+1',
      '.2'
    }, parts

  it 'lexes ordinary names as identifier', ->
    assert.same { 'hi', '_var', 'take2' }, result "hi _var take2", 'identifier'

  it 'handles operators', ->
    assert.same { '+', ',', '~=', '{', '(', ')', '/', '}', ',', 'or=' }, result '1+2, ~= {(a)/x}, or=', 'operator'

  it 'handles members', ->
    assert.same { '@foo', 'self.foo', '@_private' }, result " @foo self.foo @_private ", 'member'

  it 'lexes true, false and nil as special', ->
    assert.same { 'true', 'false', 'nil' }, result "if true then false else nil", 'special'

  it 'lexes capitalized identifiers as class', ->
    assert.same { 'Foo' }, result "class Foo", 'class'

  it 'lexes all valid key formats as key', ->
    assert.same { ':ref', 'plain:', "'string key':" }, result ":ref, plain: true, 'string key': oh_yes", 'key'

  it 'lexes illegal identifiers as error', ->
    assert.same { 'function', 'end', 'goto' }, result "function() end, end_marker goto label", 'error'

  it 'does sub-lexing within string interpolations', ->
    assert.same { '#', '{', '+', '}', '#', '{', '/', '}', ',' }, result '"#{x + y} +var+ #{z/0}", trailing', 'operator'
