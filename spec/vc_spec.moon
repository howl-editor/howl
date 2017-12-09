{:VC} = howl
{:File} = howl.io

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
      vc = {
        root: 'vc-test',
        name: 'vc',
        paths: -> {},
        files: -> {}
      }
      VC.register 'foo', find: -> nil
      VC.register 'no', find: -> nil
      VC.register 'yes', find: -> vc
      assert.equal vc, VC.for_file('file')

    it 'returns nil if no handler returns non-nil', ->
      assert.is_nil VC.for_file('file')
      VC.register 'foo', find: -> nil
      assert.is_nil VC.for_file('file')

    context 'validating the loaded vc', ->
      local vc
      before_each ->
        vc = {}
        VC.register 'vc', find: -> vc

      it 'raises an error if vc.paths() is missing', ->
        assert.raises 'paths', -> VC.for_file 'file'

      it 'raises an error if vc.root is missing', ->
        vc.paths = -> {}
        vc.name = 'vc'
        assert.raises 'root', -> VC.for_file 'file'

      it 'raises an error if vc.name is missing', ->
        vc.paths = -> {}
        vc.root = File('root')
        assert.raises 'name', -> VC.for_file 'file'

    context 'decorating the loaded vc', ->
      local vc
      before_each ->
        vc = name: 'test'
        VC.register 'vc', find: -> vc

      it 'injects a generic files() method based on paths if needed', ->
        with_tmpdir (dir) ->
          vc.root = dir
          vc.paths = -> { 'one', 'two' }
          VC.register 'with_path', find: -> vc
          inst = VC.for_file('vc')
          assert.same { dir\join('one'), dir\join('two') }, inst\files!

      it 'leaves an existing files() method alone', ->
        with_tmpdir (dir) ->
          vc.root = dir
          vc.paths = -> { 'one', 'two' }
          vc.files = -> { dir\join('three') }
          VC.register 'with_files', find: -> vc
          inst = VC.for_file('vc')
          assert.same vc\files!, inst\files!

