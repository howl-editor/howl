import File from howl.io
import paths from howl.util

pathsep = File.separator

describe 'paths', ->
  local tmpdir

  before_each ->
    tmpdir = File.tmpdir!

  after_each ->
    tmpdir\rm_r!

  describe 'get_dir_and_leftover', ->
    before_each -> File.mkdir tmpdir / 'subdir'

    it 'returns the home dir for empty input', ->
      assert.same {File.home_dir, ''}, {paths.get_dir_and_leftover ''}

    it 'returns the root directory for "/"', ->
      assert.same {File.home_dir.root_dir, ''},
        {paths.get_dir_and_leftover File.home_dir.root_dir.path}

    it 'returns the matched path and unmatched parts of a path', ->
      assert.same {tmpdir, 'unmatched'}, {paths.get_dir_and_leftover tostring(tmpdir / 'unmatched')}

    it 'when given a directory path ending in the path separator, matches the given directory', ->
      assert.same {tmpdir / 'subdir', ''}, {paths.get_dir_and_leftover tostring(tmpdir).."#{pathsep}subdir#{pathsep}"}

    it 'when given a directory path not ending in "/", matches the parent directory', ->
      assert.same {tmpdir, 'subdir'}, {paths.get_dir_and_leftover tostring(tmpdir).."#{pathsep}subdir"}

    it 'unmatched part can contain slashes', ->
      assert.same {tmpdir, "unmatched#{pathsep}no#{pathsep}such#{pathsep}file"},
        {paths.get_dir_and_leftover tostring(tmpdir / 'unmatched/no/such/file')}

    context 'is given a non absolute path', ->
      it 'uses the home dir as the base path', ->
        assert.same {File.home_dir, 'unmatched-asdf98y23903943masgb sdf'}, {paths.get_dir_and_leftover 'unmatched-asdf98y23903943masgb sdf'}

  describe 'subtree_reader', ->
    it 'returns all files and directories in a subtree', ->
      for dir in *{'a', 'b/c'}
        (tmpdir / dir)\mkdir_p!
      for file in *{'a/x', 'b/y', 'b/c/z'}
        (tmpdir / file).contents = 'a'

      files = paths.subtree_reader tmpdir
      expected = {
        'a', "a#{pathsep}x", 'b', "b#{pathsep}y", "b#{pathsep}c",
        "b#{pathsep}c#{pathsep}z"
      }
      assert.same expected, [file\relative_to_parent(tmpdir) for file in *files]
