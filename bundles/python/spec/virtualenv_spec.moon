-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:bundle, :Project, :sys} = howl
{:File, :Process} = howl.io

describe 'Python virtualenvs', ->
  local dir

  environment = -> Project(dir)\find_environment!

  make_venv = (venv) ->
    venv\mkdir_p!
    (venv / 'pyvenv.cfg').contents = 'home = /usr/bin\n'
    venv

  setup -> bundle.load_by_name 'python'
  teardown -> bundle.unload 'python'

  before_each -> dir = File.tmpdir!
  after_each -> dir\delete_all!

  it 'activates a .venv or venv in the project root, preferring .venv', ->
    venv = make_venv dir / 'venv'
    assert.same {
      VIRTUAL_ENV: venv.path
      PATH: "#{venv.path}/bin:#{sys.env.PATH}"
    }, environment!

    dot_venv = make_venv dir / '.venv'
    assert.equals dot_venv.path, environment!.VIRTUAL_ENV

  it 'ignores directories without a pyvenv.cfg', ->
    (dir / '.venv')\mkdir!
    assert.same {}, environment!

  context 'for Poetry projects', ->
    local path

    before_each ->
      bin = dir / 'bin'
      bin\mkdir!
      poetry = bin / 'poetry'
      poetry.contents = '#!/bin/sh\ntest "$*" = "env info --path" && echo "$(pwd)/elsewhere"\n'
      path = sys.env.PATH
      sys.env.PATH = "#{bin}:#{path}"

    after_each -> sys.env.PATH = path

    it "activates the virtualenv Poetry gives for the project root", (done) ->
      howl_async ->
        Process.execute { 'chmod', '+x', (dir / 'bin/poetry').path }
        venv = make_venv dir / 'elsewhere'
        (dir / 'pyproject.toml').contents = '[project]\nname = "x"\n'
        assert.same {}, environment!

        (dir / 'pyproject.toml').contents = '[tool.poetry]\nname = "x"\n'
        assert.equals venv.path, environment!.VIRTUAL_ENV

        (dir / 'pyproject.toml')\delete!
        (dir / 'poetry.lock').contents = ''
        assert.equals venv.path, environment!.VIRTUAL_ENV

        venv\delete_all!
        assert.same {}, environment!
        done!
