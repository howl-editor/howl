import bundle, config, VC from lunar
import File from lunar.fs
import Spy from lunar.spec

bundle.load_by_name 'git'

describe 'Git bundle', ->
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
      with_tmpfile (file) ->
        assert.is_nil git_vc.find file

  describe 'A Git instance', ->
    root = nil
    git = nil

    git_cmd = (args) ->
      cmd = table.concat {
        "git",
        "--git-dir='" .. root\join('.git') .. "'",
        "--work-tree='" .. root .. "'",
        args
      }, ' '
      os.execute cmd

    before_each ->
      root = File.tmpdir!
      os.execute 'git init -q ' .. root
      git = VC.available.git.find root

    after_each -> root\delete_all!

    describe '.files()', ->
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
        git_cmd 'add ' .. file\relative_to_parent root
        assert_same_files git\files!, { file }
        git_cmd 'ci -q -m "new" ' .. file\relative_to_parent root
        assert_same_files git\files!, { file }
        file.contents = 'change'
        assert_same_files git\files!, { file }

        file2 = root / 'another.lua'
        file2\touch!
        assert_same_files git\files!, { file2, file }

    it 'uses the executable in variable `git_path` if specified', ->
      orig_popen = io.popen
      pipe = read: -> 'file\n'
      wrapper = Spy as_null_object: true, with_return: pipe
      io.popen = wrapper
      config.git_path = 'foo_git'
      status, err = pcall git\files
      io.popen = orig_popen
      config.git_path = nil
      assert.match wrapper.called_with[1], 'foo_git'
