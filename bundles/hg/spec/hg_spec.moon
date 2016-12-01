import bundle, config, VC from howl
import File from howl.io

describe 'Hg bundle', ->
  setup -> bundle.load_by_name 'hg'
  teardown -> bundle.unload 'hg'

  it 'registers "hg" with VC', ->
    assert.not_nil VC.available.hg

  it 'defines a "hg_path" config variable, defaulting to nil', ->
    assert.not_nil config.definitions.hg_path
    assert.nil config.hg_path

  describe 'Hg VC find(file)', ->
    hg_vc = nil
    before_each -> hg_vc = VC.available.hg

    it 'returns a instance with .root set to the Hg root for <file> if applicable', ->
      with_tmpdir (dir) ->
        dir\join('.hg')\mkdir!
        sub = dir / 'subdir'
        for file in *{ dir, sub, sub\join('file.lua') }
          instance = hg_vc.find file
          assert.not_nil instance
          assert.equal instance.root, dir

    it 'returns nil if no hg root was found', ->
      File.with_tmpfile (file) ->
        assert.is_nil hg_vc.find file

  describe 'A Hg instance', ->
    root = nil
    hg = nil

    before_each ->
      root = File.tmpdir!
      os.execute 'hg init -q ' .. root
      hg = VC.available.hg.find root
      os.execute "cd #{root} && printf '[ui]\nusername = Howl Spec <spec@howl.io>\n' >> .hg/hgrc"

    after_each -> root\delete_all!

    describe 'files()', ->
      assert_same_files = (list1, list2) ->
        list1 = [f.path for f in *list1]
        list2 = [f.path for f in *list2]
        table.sort list1
        table.sort list2
        assert.same list1, list2

      it 'returns a list of hg files, including untracked', (done) ->
        howl_async ->
          assert_same_files hg\files!, {}
          file = root / 'new.lua'
          file\touch!
          assert_same_files hg\files!, { file }
          hg\run 'add', file\relative_to_parent root
          assert_same_files hg\files!, { file }
          hg\run 'commit', '-q', '-m', 'new', file\relative_to_parent root
          assert_same_files hg\files!, { file }
          file.contents = 'change'
          assert_same_files hg\files!, { file }

          file2 = root / 'another.lua'
          file2\touch!
          assert_same_files hg\files!, { file2, file }
          done!

    describe 'diff([file])', ->
      local file

      before_each ->
        file = root\join('new.lua')
        file.contents = 'line 1\n'
        os.execute "cd #{root} && hg add #{file}"
        os.execute "cd #{root} && hg commit -q -m 'rev1' #{file}"

      it 'returns nil if <file> has not changed', (done) ->
        howl_async ->
          assert.is_nil hg\diff file
          done!

      it 'returns a string containing the diff if <file> has changed', (done) ->
        howl_async ->
          file.contents ..= 'line 2\n'
          diff = hg\diff file
          assert.includes diff, file.basename
          assert.includes diff, '+line 2'
          done!

      it 'returns a diff for the entire directory if file is not specified', (done) ->
        howl_async ->
          file.contents ..= 'line 2\n'
          diff = hg\diff!
          assert.includes diff, file.basename
          assert.includes diff, '+line 2'
          done!

    describe 'run(...)', ->
      it 'runs hg in the root dir with the given arguments and returns the output', (done) ->
        howl_async ->
          assert.includes hg\run('showconfig', 'ui.username'), "Howl Spec"
          done!

      it 'uses the executable in variable `hg_path` if specified', (done) ->
        howl_async ->
          config.hg_path = '/bin/echo'
          status, out = pcall hg.run, hg, 'using echo'
          config.hg_path = nil
          assert status, out
          assert.includes out, "using echo"
          done!
