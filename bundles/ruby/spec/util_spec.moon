-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:bundle} = howl
{:File} = howl.io
{:env} = howl.sys

describe 'bundle.ruby.util', ->
  local util

  setup ->
    bundle.load_by_name 'ruby'
    util = _G.bundles.ruby.util

  teardown -> bundle.unload 'ruby'

  describe 'ruby_version_for(path)', ->
    it 'supports .ruby-version files', ->
      with_tmpdir (dir) ->
        ruby_version = dir / '.ruby-version'
        ruby_version.contents = '2.3\n'
        root_file = dir / 'root.rb'
        root_file\touch!
        sub_file = dir\join('sub/below.rb')
        sub_file\mkdir_p!
        for path in *{root_file, sub_file, dir}
          assert.equal '2.3', util.ruby_version_for path

    it 'returns nil if no particular version is found', ->
      with_tmpdir (dir) ->
        assert.is_nil util.ruby_version_for dir\join('sub.rb')
        assert.is_nil util.ruby_version_for dir

  describe 'ruby_command_for(path)', ->
    REAL_HOME = env.HOME

    describe 'with a .ruby-version file present', ->
      local dir

      before_each ->
        dir = File.tmpdir!
        ruby_version = dir / '.ruby-version'
        ruby_version.contents = '2.3\n'
        env.HOME = dir.path

      after_each ->
        env.HOME = REAL_HOME
        dir\delete_all! if dir.exists

      it 'returns a matching executable from the rvm rubies if possible', ->
        exec = with dir\join('.rvm/wrappers/ruby-2.3.0/ruby')
          \mkdir_p!
          \touch!

        assert.equals exec.path, util.ruby_command_for dir
