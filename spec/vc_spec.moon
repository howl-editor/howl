import VC from lunar

describe 'VC', ->
  after -> VC.unregister name for name in pairs VC.available

  describe '.register(name, handler)', ->
    it 'raises an error if name is missing', ->
      assert_raises 'name', -> VC.register nil

    it 'raises an error if handler is missing or incomplete', ->
      assert_raises 'handler', -> VC.register 'foo', nil
      assert_raises '.find', -> VC.register 'foo', {}

  it '.available is a table of all available vcs', ->
    handler = find: -> nil
    VC.register 'foo', handler
    assert_table_equal VC.available, foo: handler

  describe '.unregister(name)', ->
    it 'raises an error if name is missing', ->
      assert_raises 'name', -> VC.unregister nil

    it 'removes the specified vc from .available', ->
      VC.register 'foo', find: -> nil
      VC.unregister 'foo'
      assert_nil VC.available.foo

  describe 'for_file(file)', ->
    it 'returns the first non-nil find()-result from handlers', ->
      vc = root: '', files: -> {}
      VC.register 'foo', find: -> nil
      VC.register 'no', find: -> nil
      VC.register 'yes', find: -> vc
      assert_equal VC.for_file('file'), vc

    it 'returns nil if no handler returns non-nil', ->
      assert_nil VC.for_file('file')
      VC.register 'foo', find: -> nil
      assert_nil VC.for_file('file')

    context 'validating the loaded vc', ->
      vc = nil
      before ->
        vc = {}
        VC.register 'vc', find: -> vc

      it 'raises an error if vc.files() is missing', ->
        assert_raises 'files', -> VC.for_file 'file'

      it 'raises an error if vc.root is missing', ->
        vc.files = -> {}
        assert_raises 'root', -> VC.for_file 'file'
