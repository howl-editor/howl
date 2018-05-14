{:config, :Project, :VC} = howl
{:File} = howl.io

describe 'Project', ->
  before_each ->
    Project.roots = {}

  after_each ->
    Project.roots = {}
    Project.open = {}

  it '.roots contains all known roots', ->
    assert.same {}, Project.roots
    with_tmpdir (dir) ->
      Project.add_root dir
      assert.same {dir}, Project.roots

  it '.add_root adds the given root if not already present', ->
    with_tmpdir (dir) ->
      Project.add_root dir
      Project.add_root dir
      assert.equal 1, #Project.roots

  it '.remove_root removes the given root', ->
    with_tmpdir (dir) ->
      Project.add_root dir
      Project.remove_root dir
      assert.equal 0, #Project.roots

  describe '.for_file(file)', ->
    it 'raises an error if file is nil', ->
      assert.raises 'file', -> Project.for_file nil

    it 'returns nil by default', ->
      File.with_tmpfile (file) ->
        assert.is_nil Project.for_file file

    context 'when there is VC found for the file', ->
      vc = name: 'p-vc', root: 'foo_root', paths: -> {}, files: -> {}
      before_each -> VC.register 'pvc', find: -> vc
      after_each -> VC.unregister 'pvc'

      it 'returns a project instantiated with the vc and vc root', ->
        p = Project.for_file 'file'
        assert.not_nil p
        assert.equal vc.root, p.root
        assert.equal 'p-vc', p.vc.name

      it 'adds the new root to .roots', ->
        Project.for_file 'file'
        assert.same Project.roots, {vc.root}

      it 'adds a new entry for the root and project to .open', ->
        p = Project.for_file 'file'
        assert.same Project.open, { [vc.root]: p }

    context 'when there is a known root containing the file', ->
      it 'returns a new project for the root', ->
        with_tmpdir (dir) ->
          Project.add_root dir
          file = dir / 'test.moon'
          p = Project.for_file file
          assert.not_nil p
          assert.equal p.root, dir

      it 'automatically sets the matching VC if possible', ->
        with_tmpdir (dir) ->
          Project.add_root dir
          file = dir / 'test.moon'
          vc = name: 'p2vc', root: dir, paths: -> {}
          VC.register 'p2vc', find: (f) -> return vc if f == file
          p = Project.for_file file
          VC.unregister 'p2vc'
          assert.equal 'p2vc', p.vc.name

    context 'when there is an open project containing the file', ->
      it 'returns the existing project', ->
        with_tmpdir (dir) ->
          Project.add_root dir
          file = dir / 'test.moon'
          file2 = dir / 'test2.moon'
          p = Project.for_file file
          p2 = Project.for_file file2
          assert.not_nil p
          assert.equal p2, p

  describe 'for a given project instance', ->
    describe 'paths()', ->
      it 'delegates to .vc.paths() if it is available', ->
        vc = paths: -> {'path'}
        assert.same vc.paths!, Project('root', vc)\paths!

      it 'falls back to a FS scan, skipping directories, backup files and hidden exts', ->
        orig_exts = config.hidden_file_extensions
        config.hidden_file_extensions = {'foo'}
        with_tmpdir (dir) ->
          regular = dir / 'regular.lua'
          regular\touch!
          sub_dir = dir / 'sub_dir'
          sub_dir\mkdir!
          hidden = dir / '.config'
          hidden\touch!
          backup = dir / 'config~'
          backup\touch!
          hidden_ext = dir / 'bar.foo'
          hidden_ext\touch!
          paths = Project(dir)\paths!
          config.hidden_file_extensions = orig_exts
          table.sort paths
          assert.same { '.config', 'regular.lua' }, paths

    describe 'files()', ->
      it 'delegates to .vc.files() if it is available', ->
        vc = files: -> 'files'
        assert.equal vc.files!, Project('root', vc)\files!

      it 'falls back to a FS scan, skipping directories and backup files', ->
        with_tmpdir (dir) ->
          regular = dir / 'regular.lua'
          regular\touch!
          sub_dir = dir / 'sub_dir'
          sub_dir\mkdir!
          hidden = dir / '.config'
          hidden\touch!
          backup = dir / 'config~'
          backup\touch!
          assert.same { regular.path, hidden.path }, [f.path for f in *Project(dir)\files!]
