import mode from lunar
import File from lunar.fs

describe 'mode', ->
  after -> for name in pairs mode do mode.unregister name

  describe '.register(spec)', ->
    it 'raises an error if any of the mandatory inputs are missing', ->
      assert_raises 'name', -> mode.register {}
      assert_raises 'create', -> mode.register name: 'foo'

  it '.by_name(name) returns a mode instance with <name>, or nil if not existing', ->
    assert_nil mode.by_name 'blargh'
    instance = {}

    mode.register name: 'shish', create: -> instance
    assert_equal mode.by_name('shish'), instance

  describe '.for_file(file)', ->
    context 'when the file extension is registered with a mode', ->
      it 'returns an instance of that mode', ->
        instance = {}
        mode.register name: 'ext', extensions: 'foo', create: -> instance
        file = File 'test.foo'
        assert_equal mode.for_file(file), instance

    context 'when the file extension is not registered with any mode', ->
      it 'returns an instance of the mode "default"', ->
        instance = {}
        mode.register name: 'default', create: -> instance
        file = File 'test.blargh'
        assert_equal mode.for_file(file), instance

  it 'mode instances are memoized', ->
    mode.register name: 'same', extensions: 'again', create: -> {}
    assert_equal mode.by_name('same'), mode.for_file File 'once.again'

  it 'mode instances automatically have their .name set', ->
    mode.register name: 'named', extensions: 'again', create: -> {}
    assert_equal mode.by_name('named').name, 'named'

  describe '.unregister(name)', ->
    it '.unregister(name) removes the mode specified by <name>', ->
      mode.register name: 'mode', extensions: 'zen', create: -> {}
      mode.unregister 'mode'
      assert_nil mode.by_name 'mode'
      assert_equal mode.for_file(File('test.zen')), mode.by_name 'default'

    it 'removes any memoized instance', ->
      mode.register name: 'memo', extensions: 'memo', create: -> {}
      mode.unregister 'memo'
      instance = {}
      mode.register name: 'memo', extensions: 'memo', create: -> instance
      assert_equal mode.by_name('memo'), instance

  it '.names contains all registered mode names', ->
    mode.register name: 'needle', create: -> {}
    names = [name for name in *mode.names when name == 'needle']
    assert_table_equal names, { 'needle' }
