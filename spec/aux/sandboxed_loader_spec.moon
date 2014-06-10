import File from howl.io
import SandboxedLoader from howl.aux

describe 'SandboxedLoader', ->
  local loader, dir

  before_each ->
    dir = File.tmpdir!
    loader = SandboxedLoader dir, 'foo', {}

  after_each -> dir\rm_r!

  it 'returns a Sandbox', ->
    assert.equals 'Sandbox', typeof loader

  context 'exposed sandbox helpers', ->
    it '<name>_file(rel_path)', ->
      it 'returns a File object for the given file', ->
        f = dir\join('file.lua')
        assert.equals dir\join('file.lua'), loader -> foo_file 'file.lua'

    describe '<name>_load(rel_basename)', ->
      it 'loads relative bytecode, lua and moonscript files', ->
        dir\join('aux_lua.lua').contents = '_G.loaded_lua = true'
        dir\join('aux_moon.moon').contents = '_G.loaded_moon = true'
        dir\join('aux_bc.bc').contents = string.dump loadstring('_G.loaded_bc = true'), false
        loader ->
          foo_load 'aux_lua'
          foo_load 'aux_moon'
          foo_load 'aux_bc'

        assert.is_true _G.loaded_lua
        assert.is_true _G.loaded_moon
        assert.is_true _G.loaded_bc

      it 'prefers bytecode to Lua to Moonscript', ->
        dir\join('one.bc').contents = string.dump loadstring('return "bytecode"'), false
        dir\join('one.lua').contents = 'return "lua"'

        dir\join('two.lua').contents = 'return "lua"'
        dir\join('two.moon').contents = 'return "moon"'

        assert.equal 'bytecode', loader -> foo_load 'one'
        assert.equal 'lua', loader -> foo_load 'two'

      it 'only loads each file once', ->
        dir\join('aux.lua').contents = [[
          _G.load_count = _G.load_count or 0
          _G.load_count = _G.load_count + 1
          return _G.load_count
        ]]
        assert.equals 1, loader -> foo_load 'aux'
        assert.equals 1, loader -> foo_load 'aux'

      context '(loading files from sub directories)', ->
        it 'supports both slashes and dots in the path', ->
          sub = dir\join('down/sub.lua')
          sub.parent\mkdir!
          sub.contents = 'return "sub"'

          dir\join('down/sub2.lua').contents = 'return "sub2"'

          assert.equals 'sub', loader -> foo_load 'down/sub'
          assert.equals 'sub2', loader -> foo_load 'down.sub2'

        it 'loads the file once regardless of whether dots or slashes are used', ->
          sub = dir\join('down/sub.lua')
          sub.parent\mkdir!
          sub.contents = [[
            _G.load_count = _G.load_count + 1
            return _G.load_count
          ]]
          _G.load_count = 0
          assert.equals 1, loader -> foo_load 'down/sub'
          assert.equals 1, loader -> foo_load 'down.sub'

      it 'signals an error upon cyclic dependencies', ->
        dir\join('aux.lua').contents = 'foo_load("aux2")'
        dir\join('aux2.lua').contents = 'foo_load("aux")'
        assert.raises 'Cyclic dependency', -> loader -> foo_load 'aux'

      it 'allows passing parameters to the loaded file', ->
        dir\join('aux.lua').contents = 'return ...'
        assert.equal 123, loader -> foo_load 'aux', 123
