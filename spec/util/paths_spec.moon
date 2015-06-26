import File from howl.io
import paths from howl.util

describe 'paths', ->
  local tmpdir

  before_each ->
    tmpdir = File.tmpdir!
    File.mkdir tmpdir / 'subdir'

  after_each ->
    tmpdir\rm_r!

  describe 'get_dir_and_leftover', ->
    it 'returns the home dir for empty input', ->
      assert.same {File.home_dir, ''}, {paths.get_dir_and_leftover ''}

    it 'returns the root directory for "/"', ->
      assert.same {File.home_dir.root_dir, ''}, {paths.get_dir_and_leftover '/'}

    it 'returns the matched path and unmatched parts of a path', ->
      assert.same {tmpdir, 'unmatched'}, {paths.get_dir_and_leftover tostring(tmpdir / 'unmatched')}

    it 'when given a directory path ending in "/", matches the given directory', ->
      assert.same {tmpdir / 'subdir', ''}, {paths.get_dir_and_leftover tostring(tmpdir)..'/subdir/'}

    it 'when given a directory path not ending in "/", matches the parent directory', ->
      assert.same {tmpdir, 'subdir'}, {paths.get_dir_and_leftover tostring(tmpdir)..'/subdir'}

    it 'unmatched part can contain slashes', ->
      assert.same {tmpdir, 'unmatched/no/such/file'}, {paths.get_dir_and_leftover tostring(tmpdir / 'unmatched/no/such/file')}

    context 'is given a non absolute path', ->
      it 'uses the home dir as the base path', ->
        assert.same {File.home_dir, 'unmatched-asdf98y23903943masgb sdf'}, {paths.get_dir_and_leftover 'unmatched-asdf98y23903943masgb sdf'}
