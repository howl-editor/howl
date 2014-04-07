import Settings from howl
import File from howl.io

describe 'Settings', ->
  local tmpdir, settings

  before_each ->
    tmpdir = File.tmpdir!
    settings = Settings tmpdir

  after_each ->
    tmpdir\rm_r!

  describe 'new(dir)', ->
    it 'creates <dir> if does not exist, and its parent exists', ->
      target = tmpdir / 'foo'
      Settings target
      assert.is_true target.exists

      target = tmpdir\join('bar', 'sub')
      Settings target
      assert.is_false target.exists

    context 'when <dir> is not provided', ->
      it 'uses "$HOWL_DIR" when specified', ->
        with_tmpdir (dir) ->
          getenv = os.getenv
          os.getenv = (name) -> tostring dir.path if name == 'HOWL_DIR'
          pcall Settings
          os.getenv = getenv
          assert.is_true dir\join('system').exists

      it 'defaults to "$HOME/.howl"', ->
        with_tmpdir (dir) ->
          getenv = os.getenv
          os.getenv = (name) -> tostring dir.path if name == 'HOME'
          pcall Settings
          os.getenv = getenv
          assert.is_true dir\join('.howl').exists

  it '.dir is set to the settings directory if available', ->
    assert.equal tmpdir, Settings(tmpdir).dir
    assert.is_nil Settings(tmpdir\join('sub', 'bar')).dir

  describe 'load_user()', ->
    it 'evaluates one of {init.lua, init.moon} if found, in that order', ->
      init_moon = tmpdir\join('init.moon')
      init_moon.contents = '_G.__init_moon = true'

      settings\load_user!
      assert.equal true, __init_moon

      _G.__init_moon = false
      init_lua = tmpdir\join('init.lua')
      init_lua.contents = '_G.__init_lua = true'

      settings\load_user!
      assert.is_true __init_lua
      assert.is_false __init_moon

    it 'does nothing if the directory is not set', ->
      assert.has.no_error -> Settings(tmpdir\join('sub', 'bar'))\load_user!

    it 'raises an error if there is a problem loading the init file', ->
      tmpdir\join('init.moon').contents = 'UGH!'
      assert.raises 'UGH', -> Settings(tmpdir)\load_user!

    it 'exposes a user_load helper for loading additional files', ->
      init_lua = tmpdir\join('init.lua')
      tmpdir\join('more.lua').contents = 'return "more"'
      sub = tmpdir\join('ext', 'sub.lua')
      sub.parent\mkdir!
      sub.contents = 'return "sub"'
      init_lua.contents = [[
        _G.__loaded = user_load("more")
        _G.__loaded_sub = user_load("ext/sub")
      ]]

      settings\load_user!
      assert.equal "more", _G.__loaded
      assert.equal "sub", _G.__loaded_sub

  describe 'load_system(name)', ->
   it 'returns the loaded contents of a file named system/<name>.lua', ->
      sysdir = tmpdir / 'system'
      sysdir\join('foo.lua').contents = 'return { a = "bar" }'
      assert.same {a: 'bar'}, settings\load_system 'foo'

   it 'returns nil if the the file does not exist', ->
      assert.is_nil settings\load_system 'no_such_file'

  describe 'save_system(name, table)', ->
    it 'saves the table to a loadeable file system/<name>.lua', ->
      settings\save_system 'saved', a: 'bar'
      file = tmpdir / 'system/saved.lua'
      assert.is_true file.exists
      assert.same {a: 'bar'}, loadfile(file)!
