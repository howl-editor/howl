import bundle from howl
import File from howl.fs

describe 'bundle', ->
  after_each ->
    _G.bundles = {}
    bundle.dirs = {}

  with_bundle_dir = (name, f) ->
    with_tmpdir (dir) ->
      b_dir = dir / name
      b_dir\mkdir!
      f b_dir

  bundle_init = (info = {}, spec = {}) ->
    mod = name: 'bundle_test', author: 'bundle_spec', description: 'spec_bundle', license: 'MIT'
    mod[k] = v for k,v in pairs info
    ret = 'return { info = {'
    ret ..= table.concat [k .. '="' .. v .. '"' for k,v in pairs mod], ','
    ret ..= '}, '
    if spec.unload
      ret ..= "unload = #{spec.unload} }"
    else
      ret ..= 'unload = function() end }'
    ret

  describe 'load_from_dir(dir)', ->
    it 'raises an error if dir is not a directory', ->
      assert.raises 'directory', -> bundle.load_from_dir File '/not-a-directory'

    it 'raises an error if the bundle init file is missing or incomplete', ->
      with_tmpdir (dir) ->
        assert.raises 'bundle init', -> bundle.load_from_dir dir
        init = dir / 'init.lua'
        init\touch!
        assert.raises 'Incorrect bundle', -> bundle.load_from_dir dir
        init.contents = 'return {}'
        assert.raises 'info missing', -> bundle.load_from_dir dir
        init.contents = 'return { info = {} }'
        assert.raises 'missing info field', -> bundle.load_from_dir dir

    it 'assigns the returned bundle table to bundles using the dir basename', ->
      mod = name: 'bundle_test', author: 'bundle_spec', description: 'spec_bundle', license: 'MIT'
      with_bundle_dir 'foo', (dir) ->
        dir\join('init.lua').contents = bundle_init mod
        bundle.load_from_dir dir
        assert.same bundles.foo.info, mod
        assert.is_equal 'function', type bundles.foo.unload

    it 'massages the assigned module name to fit with naming standards if necessary', ->
      with_bundle_dir 'Test-hello 2', (dir) ->
        dir\join('init.lua').contents = bundle_init!
        bundle.load_from_dir dir
        assert.not_nil bundles.test_hello_2

    context 'exposed bundle helpers', ->
      it 'bundle_file provides access to bundle files', ->
        with_bundle_dir 'test', (dir) ->
          dir\join('init.lua').contents = [[
            local file = bundle_file('bundle_aux.lua')
            return {
              info = {
                name = 'test',
                author = 'spec',
                description = 'desc',
                license = 'MIT',
              },
              unload = function() end,
              file = file
            }
          ]]
          bundle.load_from_dir dir
          assert.equal bundles.test.file, dir / 'bundle_aux.lua'

      describe 'bundle_load', ->
        it 'allows for cached loading of bundle files using relative paths', ->
          with_bundle_dir 'load', (dir) ->
            dir\join('aux.lua').contents = [[
              _G.load_count = _G.load_count or 0
              _G.load_count = _G.load_count + 1
              return 'foo' .. _G.load_count
            ]]
            dir\join('aux2.moon').contents = 'return bundle_load("aux.lua")'
            dir\join('init.lua').contents = [[
              bundle_load('aux.lua')
              return {
                info = {
                  name = 'test',
                  author = 'spec',
                  description = 'desc',
                  license = 'MIT',
                },
                unload = function() end,
                aux = bundle_load('aux.lua'),
                aux2 = bundle_load('aux2.moon')
              }
            ]]
            bundle.load_from_dir dir
            assert.equal bundles.load.aux, 'foo1'
            assert.equal bundles.load.aux2, 'foo1'

        it 'signals an error upon cyclic dependencies', ->
          with_bundle_dir 'cyclic', (dir) ->
            dir\join('aux.lua').contents = 'bundle_load("aux2.lua")'
            dir\join('aux2.lua').contents = 'bundle_load("aux.lua")'
            dir\join('init.lua').contents = [[
              bundle_load('aux.lua')
              return {
                info = {
                  name = 'test',
                  author = 'spec',
                  description = 'desc',
                  license = 'MIT',
                },
              }
            ]]
            assert.raises 'Cyclic dependency', -> bundle.load_from_dir dir

        it 'allows passing parameters to the loaded file', ->
          with_bundle_dir 'load', (dir) ->
            dir\join('aux.lua').contents = 'return ...'
            dir\join('init.lua').contents = [[
              return {
                info = {
                  name = 'test',
                  author = 'spec',
                  description = 'desc',
                  license = 'MIT',
                },
                unload = function() end,
                aux = bundle_load('aux.lua', 123),
              }
            ]]
            bundle.load_from_dir dir
            assert.equal bundles.load.aux, 123

    it 'raises an error upon implicit global writes', ->
      with_tmpdir (dir) ->
        dir\join('init.lua').contents = [[
          file = bundle_file('bundle_aux.lua')
          return {
            info = {
              name = 'test',
              author = 'spec',
              description = 'desc',
              license = 'MIT',
            },
            file = file
          }
        ]]
        assert.raises 'implicit global', -> bundle.load_from_dir dir

  describe 'load_all()', ->
    it 'loads all found bundles in all directories in bundle.dirs', ->
      with_tmpdir (dir) ->
        bundle.dirs = {dir}
        for name in *{'foo', 'bar'}
          b_dir = dir / name
          b_dir\mkdir!
          b_dir\join('init.lua').contents = bundle_init :name

        bundle.load_all!
        assert.not_nil bundles.foo
        assert.not_nil bundles.bar

    it 'skips any hidden entries', ->
      with_tmpdir (dir) ->
        bundle.dirs = {dir}
        b_dir = dir / '.hidden'
        b_dir\mkdir!
        b_dir\join('init.lua').contents = bundle_init name: 'hidden'

        bundle.load_all!
        assert.same [name for name, _ in pairs _G.bundles], {}

  describe 'load_by_name(name)', ->
    it 'loads the bundle with the specified name', ->
      with_tmpdir (dir) ->
        bundle.dirs = {dir}
        b_dir = dir / 'named'
        b_dir\mkdir!
        b_dir\join('init.lua').contents = bundle_init name: 'named'

        bundle.load_by_name 'named'
        assert.not_nil _G.bundles.named

    it 'raises an error if the bundle could not be found', ->
      assert.raises 'not found', -> bundle.load_by_name 'oh_bundle_where_art_thouh'

  describe 'unload(name)', ->
    it 'raises an error if no bundle with the given name exists', ->
      assert.raises 'not found', -> bundle.unload 'serenity'

    context 'for an existing bundle', ->
      mod = name: 'bunny'

      it 'calls the bundle unload function and removes the bundle from _G.bundles', ->
        with_bundle_dir 'bunny', (dir) ->
          dir\join('init.lua').contents = bundle_init mod, unload: 'function() _G.bunny_bundle_unload = true end'
          bundle.load_from_dir dir
          bundle.unload 'bunny'
          assert.is_true _G.bunny_bundle_unload
          assert.is_nil bundles.bunny

      it 'returns early with an error if the unload function raises an error', ->
        with_bundle_dir 'bad_seed', (dir) ->
          dir\join('init.lua').contents = bundle_init mod, unload: 'function() error("barf!") end'
          bundle.load_from_dir dir
          assert.raises 'barf!', -> bundle.unload 'bad_seed'
          assert.is_not_nil bundles.bad_seed

      it 'transforms the given name to match the module name', ->
        with_bundle_dir 'dash-love', (dir) ->
          dir\join('init.lua').contents = bundle_init name: 'dash-love'
          bundle.load_from_dir dir
          assert.no_error -> bundle.unload 'dash-love'
