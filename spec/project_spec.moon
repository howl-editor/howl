import Project, VC from lunar

describe 'Project', ->
  after ->
    Project.roots = {}
    Project.open = {}

  it '.roots contains all known roots', ->
    assert_table_equal Project.roots, {}
    with_tmpdir (dir) ->
      Project.add_root dir
      assert_table_equal Project.roots, {dir}

  it '.add_root only adds the given root if not already present', ->
    with_tmpdir (dir) ->
      Project.add_root dir
      Project.add_root dir
      assert_equal #Project.roots, 1

  describe '.for_file(file)', ->
    it 'raises an error if file is nil', ->
      assert_raises 'file', -> Project.for_file nil

    it 'returns nil by default', ->
      with_tmpfile (file) ->
        assert_nil Project.for_file file

    context 'when there is VC found for the file', ->
      vc = root: 'foo_root', files: -> {}
      before -> VC.register 'vc', find: -> vc
      after -> VC.unregister 'vc'

      it 'returns a project instantiaded with the vc and vc root', ->
        p = Project.for_file 'file'
        assert_not_nil p
        assert_equal p.root, vc.root
        assert_equal p.vc, vc

      it 'adds the new root to .roots', ->
        Project.for_file 'file'
        assert_table_equal Project.roots, {vc.root}

      it 'adds a new entry for the root and project to .open', ->
        p = Project.for_file 'file'
        assert_table_equal Project.open, { [vc.root]: p }

    context 'when there is a known root containing the file', ->
      it 'returns a new project for the root', ->
        with_tmpdir (dir) ->
          Project.add_root dir
          file = dir / 'test.moon'
          p = Project.for_file file
          assert_not_nil p
          assert_equal p.root, dir

      it 'automatically sets the matching VC if possible', ->
        with_tmpdir (dir) ->
          Project.add_root dir
          file = dir / 'test.moon'
          vc = root: dir, files: -> {}
          VC.register 'vc', find: (file) -> return vc if file == file
          p = Project.for_file file
          VC.unregister 'vc'
          assert_equal p.vc, vc

    context 'when there is an open project containing the file', ->
      it 'returns the existing project', ->
        with_tmpdir (dir) ->
          Project.add_root dir
          file = dir / 'test.moon'
          file2 = dir / 'test2.moon'
          p = Project.for_file file
          p2 = Project.for_file file
          assert_not_nil p
          assert_equal p2, p

  describe 'for a given project instance', ->
    describe '.files()', ->
      it 'delegates to .vc.files() if it is available', ->
        vc = files: -> 'files'
        assert_equal Project('root', vc)\files!, vc.files!

      it 'falls back to a FS scan, skipping hidden and backup files', ->
        with_tmpdir (dir) ->
          regular = dir / 'regular.lua'
          regular\touch!
          hidden = dir / '.config'
          hidden\touch!
          backup = dir / 'config~'
          backup\touch!
          assert_table_equal [f.path for f in *Project(dir)\files!], { regular.path }
