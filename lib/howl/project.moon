-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import config, VC, interact from howl

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
          prompt: '\n'
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
      files = @root\find filter: (file) -> file.is_hidden or file.is_backup
      [f for f in *files when not f.is_directory]

return Project
