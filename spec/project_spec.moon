import Project, VC from howl
import File from howl.fs

describe 'Project', ->
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
      vc = root: 'foo_root', files: -> {}
      before_each -> VC.register 'vc', find: -> vc
      after_each -> VC.unregister 'vc'

      it 'returns a project instantiated with the vc and vc root', ->
        p = Project.for_file 'file'
        assert.not_nil p
        assert.equal p.root, vc.root
        assert.equal p.vc, vc

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
          vc = root: dir, files: -> {}
          VC.register 'vc', find: (file) -> return vc if file == file
          p = Project.for_file file
          VC.unregister 'vc'
          assert.equal p.vc, vc

    context 'when there is an open project containing the file', ->
      it 'returns the existing project', ->
        with_tmpdir (dir) ->
          Project.add_root dir
          file = dir / 'test.moon'
          file2 = dir / 'test2.moon'
          p = Project.for_file file
          p2 = Project.for_file file
          assert.not_nil p
          assert.equal p2, p

  describe 'for a given project instance', ->
    describe '.files()', ->
      it 'delegates to .vc.files() if it is available', ->
        vc = files: -> 'files'
        assert.equal Project('root', vc)\files!, vc.files!

      it 'falls back to a FS scan, skipping hidden and backup files', ->
        with_tmpdir (dir) ->
          regular = dir / 'regular.lua'
          regular\touch!
          hidden = dir / '.config'
          hidden\touch!
          backup = dir / 'config~'
          backup\touch!
          assert.same [f.path for f in *Project(dir)\files!], { regular.path }
