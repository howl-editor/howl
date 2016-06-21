import Settings from howl
import File from howl.io
{:env} = howl.sys

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
      REAL_HOME = env.HOME

      after_each ->
        env.HOME = REAL_HOME

      it 'uses "$HOWL_DIR" when specified', ->
        env.HOWL_DIR = tmpdir.path
        status, settings = pcall Settings
        env.HOWL_DIR = nil
        assert.is_true status
        assert.equal tmpdir, settings.dir

      it 'defaults to "$HOME/.howl"', ->
        env.HOME = tmpdir.path
        status, settings = pcall Settings
        assert.is_true status
        assert.equal tmpdir\join('.howl'), settings.dir

      it 'uses "$HOME/.config/howl" if one exists', ->
        xdg_config_dir = tmpdir\join('.config')
        howl_dir = xdg_config_dir\join('howl')
        howl_dir\mkdir_p!
        env.HOME = tmpdir.path
        status, settings = pcall Settings
        assert.is_true status
        assert.equal howl_dir, settings.dir

      it 'uses "$XDG_CONFIG_HOME" when specified', ->
        xdg_config_dir = tmpdir\join('xdgconfdirname')
        howl_dir = xdg_config_dir\join('howl')
        howl_dir\mkdir_p!
        env.HOME = tmpdir.path
        env.XDG_CONFIG_HOME = xdg_config_dir.path
        status, settings = pcall Settings
        env.XDG_CONFIG_HOME = nil
        assert.is_true status
        assert.is_true howl_dir\join('system').exists

      it 'uses ~/.howl instead of ~/.config/howl if both exists', ->
        xdg_config_dir = tmpdir\join('.config')
        conf_dir = xdg_config_dir\join('howl')
        conf_dir\mkdir_p!
        dot_dir = tmpdir\join('.howl')
        dot_dir\mkdir!
        env.HOME = tmpdir.path
        status, settings = pcall Settings
        assert.is_true status
        assert.equal dot_dir, settings.dir

      it 'raises an error if no config directory can be found', ->
        assert.raises "directory", ->
          env.HOME = nil
          Settings!

  it '.dir is set to the settings directory if available', ->
    assert.equal tmpdir, Settings(tmpdir).dir
    assert.is_nil Settings(tmpdir\join('sub', 'bar')).dir

  describe 'load_user()', ->
    it 'evaluates one of {init.lua, init.moon} if found, in that order', ->
      init_moon = tmpdir\join('init.moon')
      init_moon.contents = '_G.__init_moon = true'

      settings\load_user!
      assert.equal true, _G.__init_moon

      _G.__init_moon = false
      init_lua = tmpdir\join('init.lua')
      init_lua.contents = '_G.__init_lua = true'

      settings\load_user!
      assert.is_true _G.__init_lua
      assert.is_false _G.__init_moon

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
