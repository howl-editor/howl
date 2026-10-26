{:app, :bundle, :config, :Buffer} = howl

describe 'dev bundle', ->
  setup -> bundle.load_by_name 'howl-dev'
  teardown -> bundle.unload 'howl-dev'

  describe 'when buffers are saved', ->
    local orig_root_dir

    before_each ->
      orig_root_dir = app.root_dir

    after_each ->
      app.root_dir = orig_root_dir

    it "compiles Lua, Moonscript and Howlscript files under the application's root dir", ->
      buffer = Buffer!

      with_tmpdir (dir) ->
        app.root_dir = dir

        buffer.text = 'return {}'
        buffer\save_as dir\join('l-test.lua')
        assert.is_true dir\join('l-test.bc').exists

        buffer.text = '{}'
        buffer\save_as dir\join('m-test.moon')
        assert.is_true dir\join('m-test.bc').exists

        buffer.text = 'return {}'
        buffer\save_as dir\join('h-test.howl')
        assert.is_true dir\join('h-test.bc').exists

    it "does not compile other files", ->
      buffer = Buffer!

      with_tmpdir (dir) ->
        app.root_dir = dir

        buffer.text = 'return {}'
        buffer\save_as dir\join('x-test.xlua')
        assert.is_false dir\join('x-test.bc').exists

    it "does not compile spec files", ->
      buffer = Buffer!

      with_tmpdir (dir) ->
        app.root_dir = dir

        buffer.text = '{}'
        buffer\save_as dir\join('m-test_spec.moon')
        assert.is_false dir\join('m-test_spec.bc').exists

        buffer.text = 'return {}'
        buffer\save_as dir\join('h-test_spec.howl')
        assert.is_false dir\join('h-test_spec.bc').exists

    it "does not compile the examples in a bundle's misc directory", ->
      buffer = Buffer!

      with_tmpdir (dir) ->
        app.root_dir = dir
        misc = dir\join('bundles', 'lang', 'misc')
        misc\mkdir_p!

        buffer.text = 'return {}'
        buffer\save_as misc\join('example.lua')
        assert.is_false misc\join('example.bc').exists

        buffer.text = 'return {}'
        buffer\save_as misc\join('example.howl')
        assert.is_false misc\join('example.bc').exists

    it "removes the byte code of a file that fails to compile", ->
      buffer = Buffer!

      with_tmpdir (dir) ->
        app.root_dir = dir
        bc_file = dir\join('h-test.bc')
        bc_file.contents = 'stale'

        buffer.text = 'x = ('
        buffer\save_as dir\join('h-test.howl')
        assert.is_false bc_file.exists

    it "does not try to compile files outside of the application's root dir", ->
      buffer = Buffer!

      with_tmpdir (dir) ->
        buffer.text = 'return {}'
        buffer\save_as dir\join('l-test.lua')
        assert.is_false dir\join('l-test.bc').exists

    context 'when config.howl_src_dir is set', ->
      it 'compiles files under that directory as well', ->
        buffer = Buffer!

        with_tmpdir (dir) ->
          config.howl_src_dir = dir.path
          buffer.text = '{}'
          buffer\save_as dir\join('m-test.moon')
          assert.is_true dir\join('m-test.bc').exists
