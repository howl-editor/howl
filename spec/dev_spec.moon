{:app, :Buffer} = howl
require 'howl.dev'

describe 'dev', ->
  describe 'when buffers are saved', ->
    local orig_root_dir

    before_each ->
      orig_root_dir = app.root_dir

    after_each ->
      app.root_dir = orig_root_dir

    it "compiles Lua and Moonscript files under the application's root dir", ->
      buffer = Buffer!

      with_tmpdir (dir) ->
        app.root_dir = dir

        buffer.text = 'return {}'
        buffer\save_as dir\join('l-test.lua')
        assert.is_true dir\join('l-test.bc').exists

        buffer.text = '{}'
        buffer\save_as dir\join('m-test.moon')
        assert.is_true dir\join('m-test.bc').exists

    it "does not try to compile files outside of the application's root dir", ->
      buffer = Buffer!

      with_tmpdir (dir) ->
        buffer.text = 'return {}'
        buffer\save_as dir\join('l-test.lua')
        assert.is_false dir\join('l-test.bc').exists
