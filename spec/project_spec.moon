{:Buffer, :config, :dispatch, :Project, :sys, :VC} = howl
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

    describe 'environment', ->
      local dir, project

      provide = (name, handler, files) ->
        Project.register_environment_provider :name, :handler, :files

      before_each ->
        dir = File.tmpdir!
        project = Project dir

      after_each ->
        Project.unregister_environment_provider 'test-a'
        Project.unregister_environment_provider 'test-b'
        dir\delete_all!

      describe 'find_environment()', ->
        it "combines the providers' variables in order, giving each the project and those before it", ->
          local args
          provide 'test-a', -> { A: '1', B: '1' }
          provide 'test-b', (p, vars) ->
            args = { p, moon.copy(vars) }
            { B: '2' }

          assert.same { A: '1', B: '2' }, project\find_environment!
          assert.equals project, args[1]
          assert.same { A: '1', B: '1' }, args[2]

        it 'skips providers that fail, logging the error', ->
          provide 'test-a', -> error 'no environment here'
          provide 'test-b', -> { B: '2' }
          assert.same { B: '2' }, project\find_environment!
          assert.includes log.last_error.message, 'no environment here'

        it 'adds the variables of project_env_file last, expanding references to earlier ones', ->
          provide 'test-a', -> { A: '1', B: '1' }
          (dir / '.env').contents = 'B=2\nC=${A}${HOME}\n'
          assert.same { A: '1', B: '2', C: "1#{sys.env.HOME}" }, project\find_environment!

        it 'uses the file named by project_env_file, and none when it is blank', ->
          (dir / '.env').contents = 'A=1'
          (dir / 'dev.env').contents = 'B=2'
          project.config.project_env_file = 'dev.env'
          assert.same { B: '2' }, project\find_environment!

          project = Project dir
          project.config.project_env_file = ''
          assert.same {}, project\find_environment!

        it 'keeps the variables in .environment, running the providers once', ->
          handler = spy.new -> { A: '1' }
          provide 'test-a', handler
          vars = project\find_environment!
          assert.equals vars, project.environment
          assert.equals vars, project\find_environment!
          assert.spy(handler).was_called(1)

        it 'makes callers wait while the variables are being found', ->
          handle = dispatch.park 'test-provider'
          provide 'test-a', ->
            dispatch.wait handle
            { A: '1' }

          local first, second
          dispatch.launch -> first = project\find_environment!
          dispatch.launch -> second = project\find_environment!
          assert.is_nil first
          dispatch.resume handle
          assert.same { A: '1' }, first
          assert.equals first, second

      describe 'process_env()', ->
        it 'returns nil when there are no variables', ->
          assert.is_nil project\process_env!

        it "returns Howl's environment with the variables on top", ->
          provide 'test-a', -> { HOME: '/elsewhere', HOWL_PROJECT_VAR: '1' }
          env = project\process_env!
          assert.equals '/elsewhere', env.HOME
          assert.equals '1', env.HOWL_PROJECT_VAR
          assert.equals sys.env.PATH, env.PATH

      context 'when a file is saved', ->
        local value, buffer

        save = (name) ->
          buffer.file = dir / name
          buffer\save!

        before_each ->
          value = '1'
          provide 'test-a', (-> { A: value }), { 'deps.txt' }
          Project.open[dir] = project
          buffer = Buffer {}

        it 'finds the environment again when it depends on the file, signalling any change', ->
          project\find_environment!
          with_signal_handler 'project-environment-changed', nil, (handler) ->
            save 'deps.txt'
            assert.spy(handler).was_not_called!

            value = '2'
            save 'deps.txt'
            assert.spy(handler).was_called_with { :project }

            (dir / '.env').contents = 'B=3'
            save '.env'
            assert.spy(handler).was_called(2)

          assert.same { A: '2', B: '3' }, project.environment

        it 'leaves it alone for other files, or when it is not yet found', ->
          save 'deps.txt'
          assert.is_nil project.environment

          vars = project\find_environment!
          value = '2'
          save 'other.txt'
          (dir / 'sub')\mkdir!
          save 'sub/deps.txt'
          assert.equals vars, project.environment
