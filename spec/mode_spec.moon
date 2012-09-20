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
      it 'returns an instance of the mode "Default"', ->
        instance = {}
        mode.register name: 'Default', create: -> instance
        file = File 'test.blargh'
        assert_equal mode.for_file(file), instance

  it '.unregister(name) removes the mode specified by <name>', ->
    mode.register name: 'mode', extensions: 'zen', create: -> {}
    mode.unregister 'mode'
    assert_nil mode.by_name 'mode'
    assert_raises 'No mode available', -> mode.for_file(File('test.zen'))

  it 'allows iterating through modes using pairs()', ->
    mode.register name: 'needle', create: -> {}
    names = [name for name, func in pairs mode when name == 'needle']
    assert_table_equal names, { 'needle' }
