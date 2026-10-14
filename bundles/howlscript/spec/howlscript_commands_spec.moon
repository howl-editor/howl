import bundle, command, mode from howl

describe 'howlscript commands', ->
  local commands

  setup ->
    bundle.load_by_name 'lua'
    bundle.load_by_name 'howlscript'
    commands = _G.bundles.howlscript.commands

  teardown ->
    bundle.unload 'howlscript'
    bundle.unload 'lua'

  it 'registers howlscript-eval and howlscript-print, and removes them on unload', ->
    assert.not_nil command.get 'howlscript-eval'
    assert.not_nil command.get 'howlscript-print'
    bundle.unload 'howlscript'
    assert.is_nil command.get 'howlscript-eval'
    assert.is_nil command.get 'howlscript-print'
    bundle.load_by_name 'howlscript'
    commands = _G.bundles.howlscript.commands

  describe 'dedent(text)', ->
    it 'takes the first line`s indentation off all lines', ->
      assert.equals 'if x\n  y()\n\nz()', commands.dedent '  if x\n    y()\n\n  z()'

    it 'leaves unindented text alone', ->
      assert.equals 'x = 1\n  y', commands.dedent 'x = 1\n  y'

  describe 'eval(text)', ->
    it 'returns the values of the last statement', ->
      ok, result = commands.eval 'x = 2\nx * 3, nil, "z"'
      assert.is_true ok
      assert.same { n: 3, 6, nil, 'z' }, result

    it 'handles indented selections', ->
      ok, result = commands.eval '    a = 1\n    if a\n      a + 1'
      assert.is_true ok
      assert.equals 2, result[1]

    it 'reports compile errors', ->
      ok, err = commands.eval 'print 1'
      assert.is_false ok
      assert.match err, '^howlscript%-eval:1:7: function calls need parentheses'

    it 'reports runtime errors', ->
      ok, err = commands.eval 'x = nil\nx.y'
      assert.is_false ok
      assert.match err, '^howlscript%-eval:2: '

  describe 'to_lua_buffer(text, title)', ->
    it 'returns a Lua buffer with the compiled code', ->
      buf = commands.to_lua_buffer '  x = 1\n  x + 1', 'Title'
      assert.equals mode.by_name('lua'), buf.mode
      assert.equals 'local x = 1\nreturn x + 1', buf.text
      assert.equals 'Title', buf.title
      assert.is_false buf.modified

    it 'returns a buffer with the error when the code does not compile', ->
      buf = commands.to_lua_buffer 'print 1', 'Title'
      assert.match buf.text, '^Title:1:7: function calls need parentheses'
      assert.equals 'Title', buf.title
