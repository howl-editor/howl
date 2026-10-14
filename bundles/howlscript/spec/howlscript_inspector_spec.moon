import bundle, inspect, inspection, mode, Buffer from howl

describe 'howlscript inspector', ->
  local inspector

  setup ->
    bundle.load_by_name 'lua'
    bundle.load_by_name 'howlscript'
    inspector = inspection.howlscript.factory!

  teardown ->
    bundle.unload 'howlscript'
    bundle.unload 'lua'

  buffer_with = (text) ->
    buffer = Buffer mode.by_name 'howlscript'
    buffer.text = text
    buffer

  it 'finds nothing in a buffer that compiles', ->
    assert.same {}, inspector buffer_with 'x = 1\nprint(x)'

  it 'reports a syntax error, with the byte columns of the offending token', ->
    assert.same {{
      line: 2
      byte_start_col: 7
      byte_end_col: 10
      type: 'error'
      message: 'function calls need parentheses, as in f(x, y)'
    }}, inspector buffer_with "x = 1\nprint foo"

  it 'reports a parameter shadowing a local', ->
    res = inspector buffer_with 'buffer = 1\nf = (buffer) -> buffer'
    assert.same {2, 6, 12}, {res[1].line, res[1].byte_start_col, res[1].byte_end_col}
    assert.match res[1].message, "parameter 'buffer' shadows the local declared on line 1"

  it 'marks a single character when the length of the problem is unknown', ->
    res = inspector buffer_with 'x = "abc'
    assert.same {5, 6}, {res[1].byte_start_col, res[1].byte_end_col}

  it 'marks the offending token in the buffer, past multibyte text', ->
    buffer = buffer_with "s = 'åäö' oops"
    inspect.criticize buffer
    markers = buffer.markers\find name: 'inspection'
    assert.equals 1, #markers
    assert.equals 'oops', buffer\sub markers[1].start_offset, markers[1].end_offset - 1
