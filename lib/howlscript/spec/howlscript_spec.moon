howlscript = require 'howlscript'

describe 'howlscript', ->
  describe 'to_lua(source, opts)', ->
    it 'returns the Lua for the source', ->
      assert.equals 'local x = 1', howlscript.to_lua 'x = 1'

    it 'returns nil and a formatted error for invalid source', ->
      lua, err = howlscript.to_lua 'x = (', chunkname: '@dir/file.howl'
      assert.is_nil lua
      assert.equals "dir/file.howl:1:6: unexpected end of input\n  x = (\n       ^", err

    it 'returns the error as a table too, with its byte column and length', ->
      _, _, err = howlscript.to_lua "x = 'å' foo"
      -- the å takes two bytes
      assert.same {line: 1, col: 10, len: 3, message: "unexpected 'foo'"}, err

      _, _, err = howlscript.to_lua 'buffer = 1\nf = (buffer) -> 1'
      assert.same {2, 6, 6}, {err.line, err.col, err.len}
      assert.match err.message, "parameter 'buffer' shadows"

    it 'leaves out the length when the error is not about a token of known size', ->
      _, _, err = howlscript.to_lua 'x = "abc'
      assert.same {line: 1, col: 5, message: 'unterminated string'}, err

    it 'names the source <howlscript> without a chunk name', ->
      _, err = howlscript.to_lua 'f!'
      assert.match err, '^<howlscript>:1:2:'

  describe 'loadstring(source, chunkname, env)', ->
    it 'returns a function running the source', ->
      f = howlscript.loadstring 'return ... + 1'
      assert.equals 3, f 2

    it 'uses the chunk name in runtime errors', ->
      f = howlscript.loadstring 'x = 1\nerror("boom")\nx', '=thing'
      _, err = pcall f
      assert.equals 'thing:2: boom', err

    it 'sets the environment when given', ->
      env = {}
      f = howlscript.loadstring 'export x = 1', nil, env
      f!
      assert.equals 1, env.x

    it 'returns nil and an error for invalid source', ->
      f, err = howlscript.loadstring 'x = (', '=snippet'
      assert.is_nil f
      assert.match err, '^snippet:1:6:'

  describe 'loadfile(path, env) and dofile(path)', ->
    it 'load and run files, naming them by path', ->
      with_tmpdir (dir) ->
        file = dir / 'mod.howl'
        file.contents = 'x = ...\nerror("at #{x}")\nx'
        f = howlscript.loadfile file.path
        _, err = pcall f, 'two'
        assert.equals "#{file.path}:2: at two", err
        assert.raises 'at three', -> howlscript.dofile file.path, 'three'

    it 'return nil and an error for missing files', ->
      f, err = howlscript.loadfile '/no/such/file.howl'
      assert.is_nil f
      assert.match err, 'No such file'

    it 'report compile errors with the path', ->
      with_tmpdir (dir) ->
        file = dir / 'bad.howl'
        file.contents = 'x = f 1'
        _, err = howlscript.loadfile file
        assert.match err, '^' .. file.path\gsub('%p', '%%%0') .. ':1:7:'
