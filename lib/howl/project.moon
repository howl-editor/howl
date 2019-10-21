-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:activities, :config, :VC, :interact} = howl
{:File} = howl.io

TYPE_REGULAR = File.TYPE_REGULAR
append = table.insert

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

  new: (root, vc) =>
    @root = root
    @vc = vc
    @config = config.for_file root

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

return Project
