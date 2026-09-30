-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:File, :Process} = howl.io
{:sys} = howl

is_poetry_project = (root) ->
  return true if root\join('poetry.lock').exists
  pyproject = root\join 'pyproject.toml'
  pyproject.exists and pyproject.contents\find('[tool.poetry', 1, true) != nil

-- returns the virtualenv of the project in root, if any: `.venv` or `venv` in
-- the root, or else Poetry's, which is usually kept elsewhere
virtualenv_for = (root) ->
  for name in *{ '.venv', 'venv' }
    dir = root\join name
    return dir if dir\join('pyvenv.cfg').exists

  return nil unless is_poetry_project(root) and sys.find_executable('poetry')
  out, _, p = Process.execute { 'poetry', 'env', 'info', '--path' }, working_directory: root
  path = p.successful and out.stripped
  return nil if not path or path.is_blank
  dir = File path
  dir.is_directory and dir or nil

-- activates the project's virtualenv as its `activate` script does, so that
-- language servers and commands find its packages and executables
(project, vars) ->
  venv = virtualenv_for project.root
  return nil unless venv
  {
    VIRTUAL_ENV: venv.path
    PATH: "#{venv\join('bin').path}:#{vars.PATH or sys.env.PATH}"
  }
