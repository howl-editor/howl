-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:activities, :config, :dispatch, :signal, :sys, :VC, :interact} = howl
{:File} = howl.io
{:dotenv} = howl.util

TYPE_REGULAR = File.TYPE_REGULAR
append = table.insert

-- the environment providers, in the order they were registered
providers = {}

config.define
  name: 'project_env_file'
  description: 'A file in the project root with variables for the processes run for the project (blank for none)'
  type_of: 'string'
  default: '.env'

signal.register 'project-environment-changed',
  description: 'Signaled when the environment of a project has changed, after a file it depends on was saved'
  parameters:
    project: 'The project'

same_vars = (a, b) ->
  for k, v in pairs a
    return false unless b[k] == v
  for k in pairs b
    return false if a[k] == nil
  true

root_for = (file, roots) ->
  for root in *roots
    return root if file\is_below root
  nil

open_for = (file, mapping) ->
  for root, project in pairs mapping
    return project if file\is_below root
  nil

class Project
  roots: {}
  open: {}

  for_file: (file) ->
    error 'nil for argument #1 (file)', 2 if not file
    project = open_for file, Project.open
    return project if project
    root = root_for file, Project.roots
    vc = VC.for_file file
    if root or vc
      project = Project root or vc.root, vc
      Project.open[project.root] = project
      Project.add_root project.root
      return project

    nil

  get_for_file: (file) ->
    project = Project.for_file file
    if not project
      directory = interact.select_directory
          title: '(Please specify the project root): '
          prompt: 'Project root: '
          path: file.path
      if directory
        Project.add_root directory
        project = Project.for_file file

    project

  add_root: (root) ->
    for r in *Project.roots do return if r == root
    append Project.roots, root

  remove_root: (root) ->
    Project.roots = [r for r in *Project.roots when r != root]

  -- registers a provider of environment variables for projects: `name`,
  -- `handler(project, vars)` returning a table of variables or nil, where `vars`
  -- holds those of the providers before it, and `files`, the names of files in
  -- the project root that the variables depend on
  register_environment_provider: (provider) ->
    error 'Missing field `name` for environment provider', 2 unless provider.name
    error 'Missing field `handler` for environment provider', 2 unless provider.handler
    Project.unregister_environment_provider provider.name
    append providers, provider

  unregister_environment_provider: (name) ->
    providers = [p for p in *providers when p.name != name]

  new: (root, vc) =>
    @root = root
    @vc = vc
    @config = config.for_file root

  -- finds the environment variables for the processes run for the project, on
  -- top of Howl's own: those of the providers, and then those in the
  -- `project_env_file`. They're kept in `environment`, and callers wait while
  -- they're being found. Must be called from a coroutine, since providers may
  -- run processes.
  find_environment: =>
    return @environment if @environment
    if @_env_waiters
      handle = dispatch.park 'project-environment'
      append @_env_waiters, handle
      return dispatch.wait handle

    @_env_waiters = {}
    vars = {}
    for provider in *providers
      status, ret = pcall provider.handler, @, vars
      if not status
        log.error "Failed to get the '#{provider.name}' environment for #{@root}: #{ret}"
      elseif ret
        vars[k] = v for k, v in pairs ret

    file = @_env_file!
    if file and file.exists
      lookup = (name) -> vars[name] or sys.env[name]
      status, ret = pcall -> dotenv.parse file.contents, lookup
      if status
        vars[k] = v for k, v in pairs ret
      else
        log.error "Failed to read #{file}: #{ret}"

    @environment = vars
    waiters = @_env_waiters
    @_env_waiters = nil
    dispatch.resume handle, vars for handle in *waiters
    vars

  -- the environment for a process run for the project, as `Process`'s `env`:
  -- Howl's own with the project's variables on top, or nil when there are none.
  -- Must be called from a coroutine, unless the environment is known.
  process_env: =>
    vars = @find_environment!
    return nil unless next vars
    env = {k, v for k, v in pairs sys.env}
    env[k] = v for k, v in pairs vars
    env

  _env_file: =>
    name = @config.project_env_file
    return nil if not name or name.is_blank
    @root\join name

  -- whether the environment depends on file
  _depends_on: (file) =>
    env_file = @_env_file!
    return true if env_file and file == env_file
    return false unless file.parent == @root
    name = file.basename
    for provider in *providers
      for f in *(provider.files or {})
        return true if f == name

    false

  files: =>
    if @vc and @vc.files
      @vc\files!
    else
      paths = @paths!
      activities.run {
        title: "Loading files from '#{@root}'",
        status: -> "Loading files from #{#paths} paths..",
      }, ->
        groot = @root.gfile
        return for i = 1, #paths
          activities.yield! if i % 1000 == 0
          path = paths[i]
          gfile = groot\get_child(path)
          File gfile, nil, type: TYPE_REGULAR

  paths: =>
    if @vc and @vc.paths
      @vc\paths!
    else
      activities.run {
        title: "Reading paths for '#{@root}'",
        status: -> "Reading paths for '#{@root}'",
      }, ->
        ignore = howl.util.ignore_file.evaluator @root
        hidden_exts = {ext, true for ext in *config.hidden_file_extensions}
        filter = (p) ->
          return true if p\ends_with('~')
          ext = p\match '%.(%w+)/?$'
          return true if hidden_exts[ext]
          ignore p

        @root\find_paths exclude_directories: true, :filter

-- saving a file that a project's environment depends on finds it again
signal.connect 'buffer-saved', (args) ->
  file = args.buffer.file
  return unless file
  projects = [p for _, p in pairs Project.open when p.environment and p\_depends_on file]
  for project in *projects
    old = project.environment
    project.environment = nil
    vars = project\find_environment!
    signal.emit 'project-environment-changed', :project unless same_vars old, vars

return Project
