{:Buffer, :mode, :config} = howl
{:File} = howl.io
{:Editor} = howl.ui

describe 'mode', ->
  after_each ->
    for name in *[name for name in *mode.names when name != 'default' ]
      mode.unregister name

  describe '.register(spec)', ->
    it 'raises an error if any of the mandatory inputs are missing', ->
      assert.raises 'name', -> mode.register {}
      assert.raises 'create', -> mode.register name: 'foo'

  describe '.by_name(name)', ->
    it 'returns a mode instance for <name>, or nil if not existing', ->
      assert.is_nil mode.by_name 'blargh'

      mode.register name: 'shish', create: -> {}
      assert.is_not_nil mode.by_name('shish')

    it 'allows looking up modes by any aliases', ->
      assert.is_nil mode.by_name 'my_mode'

      mode.register name: 'shish', aliases: {'my_mode'}, create: -> {}
      assert.is_not_nil mode.by_name('my_mode')

  describe 'for_extension(extension)', ->
    it 'returns a mode registered for <extension>, if any', ->
      mode.register name: 'ext', extensions: 'foo', create: -> {}
      assert.equal 'ext', mode.for_extension('foo').name

  describe '.for_file(file)', ->
    context 'when the file extension is registered with a mode', ->
      it 'returns an instance of that mode', ->
        mode.register name: 'ext', extensions: 'foo', create: -> {}
        file = File 'test.foo'
        assert.equal 'ext', mode.for_file(file).name

    context 'when the file paths matches a mode pattern', ->
      it 'returns an instance of that mode', ->
        mode.register name: 'pattern', patterns: 'match%w+$', create: -> {}
        file = File 'matchme'
        assert.equal 'pattern', mode.for_file(file).name

    context 'when the file header matches a mode shebang', ->
      it 'returns an instance of that mode', ->
        mode.register name: 'shebang', shebangs: 'lua$', create: -> {}
        File.with_tmpfile (file) ->
          file.contents = '#! /usr/bin/lua\nother line\nand other\n'
          assert.equal 'shebang', mode.for_file(file).name

    context 'when no matching mode can be found', ->
      it 'returns an instance of the mode "default"', ->
        file = File 'test.blargh'
        assert.equal 'default', mode.for_file(file).name

  context 'mode creation', ->
    it 'modes are created by calling the modes create function, passing the name', ->
      create = spy.new -> {}
      mode.register name: 'callme', :create
      mode.by_name('callme')
      assert.spy(create).was_called_with 'callme'

  it 'mode instances are memoized', ->
    mode.register name: 'same', extensions: 'again', create: -> {}
    assert.equal mode.by_name('same'), mode.for_file File 'once.again'

  it 'mode instances automatically have their .name set', ->
    mode.register name: 'named', extensions: 'again', create: -> {}
    assert.equal mode.by_name('named').name, 'named'

  describe 'mode configuration variables', ->
    config.define name: 'mode_var', description: 'some var', default: 'def value'

    it 'mode instances automatically have their .config set', ->
      mode.register name: 'config', create: -> {}
      mode_config = mode.by_name('config').config
      assert.is_not_nil mode_config

      assert.equal 'def value', mode_config.mode_var
      mode_config.mode_var = 123
      assert.equal 123, mode_config.mode_var
      assert.equal 'def value', config.mode_var

    it 'the .config is pre-seeded with variables from .default_config of the mode (if any)', ->
      mode.register name: 'pre_config', create: -> default_config: { mode_var: 543 }
      assert.equal 543, mode.by_name('pre_config').config.mode_var

    describe 'configure(mode_name, variables)', ->
      before_each ->
        mode.register name: 'user_configured', create: -> {}

      it 'allows setting mode specific variables automatically upon creation', ->
        mode.configure 'user_configured', mode_var: 'from_user'
        assert.equal 'from_user', mode.by_name('user_configured').config.mode_var

      it 'automatically sets the config variables for any already instantiated mode', ->
        mode_config = mode.by_name('user_configured').config
        mode.configure 'user_configured', mode_var: 'after_the_fact'
        assert.equal 'after_the_fact', mode_config.mode_var

      it 'overrides any default mode configuration set', ->
        mode.register name: 'mode_with_config', create: -> default_config: { mode_var: 'mode set' }
        mode.configure 'mode_with_config', mode_var: 'user set'
        assert.equal 'user set', mode.by_name('mode_with_config').config.mode_var

  describe 'mode inheritance', ->
    before_each ->
      base = foo: 'foo'
      mode.register name: 'base', create: -> base
      mode.register name: 'sub', parent: 'base', create: -> {}
      config.define name: 'delegated_mode_var', description: 'some var', default: 'def value'

    it 'a mode extending another mode automatically delegates to that mode', ->
       assert.equal 'foo', mode.by_name('sub').foo
       mode.by_name('base').config.delegated_mode_var = 123
       assert.equal 123, mode.by_name('sub').config.delegated_mode_var

    it '.parent is set to the mode parent', ->
      mode.register name: 'subsub', parent: 'sub', create: -> {}
      sub_mode = mode.by_name('sub')
      subsub_mode = mode.by_name('subsub')
      assert.equal 'base', sub_mode.parent.name
      assert.equal 'sub', subsub_mode.parent.name

    it 'overridden functions and variables other then parent are respected', ->
      mode.register name: 'first', create: -> {
        mode_var1: 'first1'
        mode_var2: 'first2'

        one: => "#{@mode_var1} #{@two!}"
        two: => @mode_var2
      }

      mode.register name: 'second', parent: 'first', create: -> {
        mode_var1: 'second1'

        two: => "#{@mode_var2}X"
      }

      second_mode = mode.by_name('second')
      assert.equal "second1 first2X", second_mode\one!

    describe 'super(...)', ->
      it 'super methods can be invoked using `super`', ->
        mode.register name: 'first', create: -> { foo: => "1" }
        mode.register name: 'second', parent: 'first', create: -> {
          foo: => super! .. '2'
        }
        mode.register name: 'third', parent: 'second', create: -> {
          foo: => super! .. '3'
          other: => 'other'
        }

        third_mode = mode.by_name('third')
        assert.equal '123', third_mode\foo!

      it 'raises an error if no parent has the specified method', ->
        mode.register name: 'wrong', create: -> {
          foo: => super!
        }
        assert.raises "No parent 'foo'", ->
          mode.by_name('wrong')\foo!

      it 'invokes the super method with the correct parameters', ->
        local args
        mode.register name: 'first', create: -> {
          foo: (...) -> args = {...}
        }
        mode.register name: 'second', parent: 'first', create: -> {
          foo: (...) => super ...
        }

        second = mode.by_name('second')
        second\foo '1', 2
        assert.same {second, '1', 2}, args

      it 'works when deriving from the default mode implicitly', ->
        mode.register name: 'implicit', create: -> {
          comment_syntax: '--'
          comment: (editor) => super editor
        }
        buf = Buffer {}
        buf.text = 'line 1\nline2'
        editor = Editor buf

        mode.by_name('implicit')\comment editor
        assert.equal '-- line 1\nline2', buf.text

    it 'an error is raised if the mode indicated by parent does not exist', ->
      assert.has_error ->
        mode.register name: 'wrong', parent: 'keyser_soze', create: -> {}
        mode.by_name 'wrong'

    it 'parent defaults to "default" unless given', ->
      mode.register name: 'orphan', create: -> {}
      assert.equal 'default', mode.by_name('orphan').parent.name

  describe '.unregister(name)', ->
    it 'removes the mode specified by <name>', ->
      mode.register name: 'mode', aliases: 'foo', extensions: 'zen', create: -> {}
      mode.unregister 'mode'
      assert.is_nil mode.by_name 'mode'
      assert.is_nil mode.by_name 'foo'
      assert.equal mode.for_file(File('test.zen')), mode.by_name 'default'

    it 'removes any memoized instance', ->
      mode.register name: 'memo', extensions: 'memo', create: -> {}
      mode.unregister 'memo'
      live = mode.by_name 'memo'
      mode.register name: 'memo', extensions: 'memo', create: -> {}
      assert.is_not_equal live, mode.by_name('memo')

  it '.names contains all registered mode names and their aliases', ->
    mode.register name: 'needle', aliases: 'foo', create: -> {}
    assert.includes mode.names, 'needle'
    assert.includes mode.names, 'foo'
