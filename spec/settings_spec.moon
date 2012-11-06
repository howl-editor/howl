import Settings from lunar
import File from lunar.fs

describe 'Settings', ->
  local tmpdir
  settings = nil

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

    it 'defaults to "$HOME/.lunar" when <dir> is not provided', ->
      getenv = os.getenv
      os.getenv = -> tmpdir.path
      pcall Settings
      os.getenv = getenv
      assert.is_true tmpdir\join('.lunar').exists

  it '.dir is set to the settings directory if available', ->
    assert.equal tmpdir, Settings(tmpdir).dir
    assert.is_nil Settings(tmpdir\join('sub', 'bar')).dir

  describe 'load_user()', ->
    it 'evaluates one of {init.moon, init.lua} if found, in that order', ->
      init_lua = tmpdir\join('init.lua')
      init_moon = tmpdir\join('init.moon')
      init_lua.contents = '_G.__init_lua = true'
      settings\load_user!
      assert.equal true, __init_lua

      init_lua.contents = '_G.__init_lua = 2'
      init_moon.contents = '_G.__init_moon = true'
      settings\load_user!
      assert.not_equal 2, __init_lua
      assert.equal true, __init_moon

    it 'does nothing if the directory is not set', ->
      assert.has.no_error -> Settings(tmpdir\join('sub', 'bar'))\load_user!

    it 'logs an error if there is a problem loading the init file', ->
      tmpdir\join('init.moon').contents = 'blarkgj!'
      Settings(tmpdir)\load_user!
      assert.is_not.equal #log.entries, 0
      assert.match log.entries[#log.entries].message, 'init.moon'
