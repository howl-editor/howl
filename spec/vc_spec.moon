import VC from howl

describe 'VC', ->
  after_each -> VC.unregister name for name in pairs VC.available

  describe '.register(name, handler)', ->
    it 'raises an error if name is missing', ->
      assert.raises 'name', -> VC.register nil

    it 'raises an error if handler is missing or incomplete', ->
      assert.raises 'handler', -> VC.register 'foo', nil
      assert.raises '.find', -> VC.register 'foo', {}

  it '.available is a table of all available vcs', ->
    handler = find: -> nil
    VC.register 'foo', handler
    assert.same VC.available, foo: handler

  describe '.unregister(name)', ->
    it 'raises an error if name is missing', ->
      assert.raises 'name', -> VC.unregister nil

    it 'removes the specified vc from .available', ->
      VC.register 'foo', find: -> nil
      VC.unregister 'foo'
      assert.is_nil VC.available.foo

  describe 'for_file(file)', ->
    it 'returns the first non-nil find()-result from handlers', ->
      vc = root: '', files: -> {}
      VC.register 'foo', find: -> nil
      VC.register 'no', find: -> nil
      VC.register 'yes', find: -> vc
      assert.equal VC.for_file('file'), vc

    it 'returns nil if no handler returns non-nil', ->
      assert.is_nil VC.for_file('file')
      VC.register 'foo', find: -> nil
      assert.is_nil VC.for_file('file')

    context 'validating the loaded vc', ->
      vc = nil
      before_each ->
        vc = {}
        VC.register 'vc', find: -> vc

      it 'raises an error if vc.files() is missing', ->
        assert.raises 'files', -> VC.for_file 'file'

      it 'raises an error if vc.root is missing', ->
        vc.files = -> {}
        assert.raises 'root', -> VC.for_file 'file'
