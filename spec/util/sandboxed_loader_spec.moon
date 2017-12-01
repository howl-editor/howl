import File from howl.io
import SandboxedLoader from howl.util

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
        assert.equals dir\join('file.lua'), loader -> foo_file 'file.lua'

    describe '<name>_load(rel_basename)', ->
      it 'loads relative bytecode, lua and moonscript files', ->
        dir\join('util_lua.lua').contents = '_G.loaded_lua = true'
        dir\join('util_moon.moon').contents = '_G.loaded_moon = true'
        dir\join('util_bc.bc').contents = string.dump loadstring('_G.loaded_bc = true'), false
        loader ->
          foo_load 'util_lua'
          foo_load 'util_moon'
          foo_load 'util_bc'

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
        dir\join('util.lua').contents = [[
          _G.load_count = _G.load_count or 0
          _G.load_count = _G.load_count + 1
          return _G.load_count
        ]]
        assert.equals 1, loader -> foo_load 'util'
        assert.equals 1, loader -> foo_load 'util'

      context '(loading files from sub directories)', ->
        local sub_dir

        before_each ->
          sub_dir = dir\join('subdir')
          sub_dir\mkdir!

        it 'supports both slashes and dots in the path', ->
          sub_dir\join('sub.lua').contents = 'return "sub"'
          sub_dir\join('sub2.lua').contents = 'return "sub2"'

          assert.equals 'sub', loader -> foo_load 'subdir/sub'
          assert.equals 'sub2', loader -> foo_load 'subdir.sub2'

        it 'loads the file once regardless of whether dots or slashes are used', ->
          sub_dir\join('sub.lua').contents = [[
            _G.load_count = _G.load_count + 1
            return _G.load_count
          ]]
          _G.load_count = 0
          assert.equals 1, loader -> foo_load 'subdir/sub'
          assert.equals 1, loader -> foo_load 'subdir.sub'

        it 'loads an implicit init file for bare directory references', ->
          sub_dir\join('init.lua').contents = 'return "lua"'
          assert.equals 'lua', loader -> foo_load 'subdir'

      it 'signals an error upon cyclic dependencies', ->
        dir\join('util.lua').contents = 'foo_load("util2")'
        dir\join('util2.lua').contents = 'foo_load("util")'
        assert.raises 'Cyclic dependency', -> loader -> foo_load 'util'

      it 'allows passing parameters to the loaded file', ->
        dir\join('util.lua').contents = 'return ...'
        assert.equal 123, loader -> foo_load 'util', 123
