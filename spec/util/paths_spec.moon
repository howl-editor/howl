import File from howl.io
import paths from howl.util

describe 'paths', ->
  local tmpdir

  before_each ->
    tmpdir = File.tmpdir!

  after_each ->
    tmpdir\rm_r!

  describe 'parse_path', ->
    it 'returns the home dir for empty input', ->
      assert.same {File.home_dir, ''}, {paths.parse_path ''}

    it 'returns the root directory for "/"', ->
      assert.same {File.home_dir.root_dir, ''}, {paths.parse_path '/'}

    it 'returns the matched path and unmatched parts of a path', ->
      assert.same {tmpdir, 'unmatched'}, {paths.parse_path tostring(tmpdir / 'unmatched')}

    it 'unmatched part can contain slashes', ->
      assert.same {tmpdir, 'unmatched/no/such/file'}, {paths.parse_path tostring(tmpdir / 'unmatched/no/such/file')}

    context 'is given a non absolute path', ->
      it 'uses the home dir as the base path', ->
        assert.same {File.home_dir, 'unmatched-asdf98y23903943masgb sdf'}, {paths.parse_path 'unmatched-asdf98y23903943masgb sdf'}
