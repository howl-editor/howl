import bundle, config, VC from howl
import File from howl.fs
import Spy from howl.spec

describe 'Git bundle', ->
  setup -> bundle.load_by_name 'git'
  teardown -> bundle.unload 'git'

  it 'registers "git" with VC', ->
    assert.not_nil VC.available.git

  it 'defines a "git_path" config variable, defaulting to nil', ->
    assert.not_nil config.definitions.git_path
    assert.nil config.git_path

  describe 'Git VC find(file)', ->
    git_vc = nil
    before_each -> git_vc = VC.available.git

    it 'returns a instance with .root set to the Git root for <file> if applicable', ->
      with_tmpdir (dir) ->
        dir\join('.git')\mkdir!
        sub = dir / 'subdir'
        for file in *{ dir, sub, sub\join('file.lua') }
          instance = git_vc.find file
          assert.not_nil instance
          assert.equal instance.root, dir

    it 'returns nil if no git root was found', ->
      File.with_tmpfile (file) ->
        assert.is_nil git_vc.find file

  describe 'A Git instance', ->
    root = nil
    git = nil

    before_each ->
      root = File.tmpdir!
      os.execute 'git init -q ' .. root
      git = VC.available.git.find root
      git\run 'config user.email "spec@howl.io"'
      git\run 'config user.name "Howl Spec"'

    after_each -> root\delete_all!

    describe 'files()', ->
      assert_same_files = (list1, list2) ->
        list1 = [f.path for f in *list1]
        list2 = [f.path for f in *list2]
        table.sort list1
        table.sort list2
        assert.same list1, list2

      it 'returns a list of git files, including untracked', ->
        assert_same_files git\files!, {}
        file = root / 'new.lua'
        file\touch!
        assert_same_files git\files!, { file }
        git\run 'add ' .. file\relative_to_parent root
        assert_same_files git\files!, { file }
        git\run 'commit -q -m "new" ' .. file\relative_to_parent root
        assert_same_files git\files!, { file }
        file.contents = 'change'
        assert_same_files git\files!, { file }

        file2 = root / 'another.lua'
        file2\touch!
        assert_same_files git\files!, { file2, file }

    describe 'diff([file])', ->
      local file

      before_each ->
        file = root\join('new.lua')
        file.contents = 'line 1\n'
        git\run "add #{file}"
        git\run "commit -q -m 'rev1' #{file}"

      it 'returns nil if <file> has not changed', ->
        assert.is_nil git\diff file

      it 'returns a string containing the diff if <file> has changed', ->
        file.contents ..= 'line 2\n'
        diff = git\diff file
        assert.includes diff, file.basename
        assert.includes diff, '+line 2'

      it 'returns a diff for the entire directory if file is not specified', ->
        file.contents ..= 'line 2\n'
        diff = git\diff!
        assert.includes diff, file.basename
        assert.includes diff, '+line 2'

    describe 'run(...)', ->
      it 'runs git in the root dir with the given arguments and returns the output', ->
        assert.includes git\run('config --local -l'), "Howl Spec"

      it 'uses the executable in variable `git_path` if specified', ->
        config.git_path = '/bin/echo'
        status, out = pcall git.run, git, 'using echo'
        config.git_path = nil
        assert status, out
        assert.includes out, "using echo"
