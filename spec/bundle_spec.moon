-- Copyright 2012-2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import bundle from howl
import File from howl.io

describe 'bundle', ->
  after_each ->
    _G.bundles = {}
    bundle.dirs = {}

  with_bundle_dir = (name, f) ->
    with_tmpdir (dir) ->
      b_dir = dir / name
      b_dir\mkdir!
      pcall f, b_dir

      mod_name = name\lower!\gsub '[%s%p]+', '_'
      pcall(bundle.unload, mod_name) if _G.bundles[mod_name]

  bundle_init = (info = {}, spec = {}) ->
    ret = ''
    ret ..= "#{spec.code}\n" if spec.code
    mod = author: 'bundle_spec', description: 'spec_bundle', license: 'MIT'
    mod[k] = v for k,v in pairs info
    ret ..= 'return { info = {'
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
        assert.raises 'find file', -> bundle.load_from_dir dir
        init = dir / 'init.lua'
        init\touch!
        assert.raises 'Incorrect bundle', -> bundle.load_from_dir dir
        init.contents = 'return {}'
        assert.raises 'info missing', -> bundle.load_from_dir dir
        init.contents = 'return { info = {} }'
        assert.raises 'missing info field', -> bundle.load_from_dir dir

    it 'assigns the returned bundle table to bundles using the dir basename', ->
      mod = author: 'bundle_spec', description: 'spec_bundle', license: 'MIT'
      with_bundle_dir 'foo', (dir) ->
        dir\join('init.lua').contents = bundle_init mod
        bundle.load_from_dir dir
        assert.same _G.bundles.foo.info, mod
        assert.is_equal 'function', type _G.bundles.foo.unload

    it 'massages the assigned module name to fit with naming standards if necessary', ->
      with_bundle_dir 'Test-hello 2', (dir) ->
        dir\join('init.lua').contents = bundle_init!
        bundle.load_from_dir dir
        assert.not_nil _G.bundles.test_hello_2

    it 'raises an error if the bundle is already loaded', ->
      with_bundle_dir 'two_times', (dir) ->
        dir\join('init.lua').contents = bundle_init!
        bundle.load_from_dir dir
        assert.raises 'loaded', -> bundle.load_from_dir dir

    context 'exposed bundle helpers', ->
      it 'bundle_file provides access to bundle files', ->
        with_bundle_dir 'test', (dir) ->
          dir\join('init.lua').contents = [[
            local file = bundle_file('bundle_aux.lua')
            return {
              info = {
                author = 'spec',
                description = 'desc',
                license = 'MIT',
              },
              unload = function() end,
              file = file
            }
          ]]
          bundle.load_from_dir dir
          assert.equal _G.bundles.test.file, dir / 'bundle_aux.lua'

      describe 'provide_module(name, prefix = nil)', ->
        it 'makes a sub directory available for loading globally with require', ->
          with_bundle_dir 'test', (dir) ->
            mod = dir\join('testmod')
            mod\mkdir_p!
            mod\join('init.moon').contents = '{root: true}'
            mod\join('other.moon').contents = '{other: true}'
            dir\join('init.lua').contents = bundle_init nil, {
              code: 'provide_module("testmod")'
            }
            bundle.load_from_dir dir
            assert.same {root: true}, require 'testmod'
            assert.same {other: true}, require 'testmod.other'

    it 'raises an error upon implicit global writes', ->
      with_tmpdir (dir) ->
        dir\join('init.lua').contents = [[
          file = bundle_file('bundle_aux.lua')
          return {
            info = {
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
        assert.not_nil _G.bundles.foo
        assert.not_nil _G.bundles.bar

    it 'skips any hidden entries', ->
      with_tmpdir (dir) ->
        bundle.dirs = {dir}
        b_dir = dir / '.hidden'
        b_dir\mkdir!
        b_dir\join('init.lua').contents = bundle_init name: 'hidden'

        bundle.load_all!
        assert.same [name for name, _ in pairs _G.bundles], {}

    it 'raises an error if bundle names conflict', ->
      with_tmpdir (dir) ->
        for name in *{'foo', 'bar'}
          b_dir = dir / name / 'my_bundle'
          b_dir\mkdir_p!
          b_dir\join('init.lua').contents = bundle_init :name
        bundle.dirs = {dir\join('foo'), dir\join('bar')}

        assert.raises 'conflict', -> bundle.load_all!

  describe 'load_by_name(name)', ->
    it 'loads the bundle with the specified name, if not already loaded', ->
      with_tmpdir (dir) ->
        bundle.dirs = {dir}
        b_dir = dir / 'named'
        b_dir\mkdir!
        b_dir\join('init.lua').contents = bundle_init name: 'named'

        bundle.load_by_name 'named'
        assert.not_nil _G.bundles.named

        assert.raises 'loaded', -> bundle.load_by_name 'named'

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
          assert.is_nil _G.bundles.bunny

      it 'returns early with an error if the unload function raises an error', ->
        with_bundle_dir 'bad_seed', (dir) ->
          dir\join('init.lua').contents = bundle_init mod, unload: 'function() error("barf!") end'
          bundle.load_from_dir dir
          assert.raises 'barf!', -> bundle.unload 'bad_seed'
          assert.is_not_nil _G.bundles.bad_seed

      it 'transforms the given name to match the module name', ->
        with_bundle_dir 'dash-love', (dir) ->
          dir\join('init.lua').contents = bundle_init name: 'dash-love'
          bundle.load_from_dir dir
          assert.no_error -> bundle.unload 'dash-love'

      it 'removes any references to provided modules', ->
        with_bundle_dir 'test', (dir) ->
          mod = dir\join('testmod')
          mod\mkdir_p!
          mod\join('init.moon').contents = '{root: true}'
          mod\join('other.moon').contents = '{other: true}'
          dir\join('init.lua').contents = bundle_init nil, {
            code: 'provide_module("testmod")'
          }
          bundle.load_from_dir dir
          assert.same {root: true}, require 'testmod'
          assert.same {other: true}, require 'testmod.other'
          bundle.unload 'test'
          assert.is_false pcall require, 'testmod'
          assert.is_false pcall require, 'testmod.other'

  describe 'from_file(file)', ->
    it 'returns the adjusted name of the containing bundle if any', ->
      with_tmpdir (dir) ->
        bundle.dirs = {dir}
        b_dir = dir / 'my-bundle'
        init = b_dir\join('init.lua')
        assert.equal 'my_bundle', bundle.from_file(init)
        assert.is_nil bundle.from_file(File('/bin/ls'))
        assert.is_nil bundle.from_file(dir\join('directly_under_root'))

  it '.unloaded holds the adjusted names of any unloaded bundles', ->
    with_tmpdir (dir) ->
      bundle.dirs = {dir}
      for name in *{'foo-bar', 'frob_nic'}
        b_dir = dir / name
        b_dir\mkdir!
        b_dir\join('init.lua').contents = bundle_init :name

      assert.same { 'foo_bar', 'frob_nic' }, bundle.unloaded
      bundle.load_by_name 'foo_bar'
      assert.same { 'frob_nic' }, bundle.unloaded
      bundle.unload 'foo_bar'
      assert.same { 'foo_bar', 'frob_nic' }, bundle.unloaded
