-- Copyright 2016-2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:app, :command, :config, :mode, :inspection, :sys, :Project} = howl

{:fmt} = bundle_load 'go_fmt'

get_go_package = (buffer) ->
  return unless buffer.file
  project = Project.for_file buffer.file
  return unless project
  go_mod = project.root / 'go.mod'
  return unless go_mod.exists
  module_line = go_mod.lines[1]
  return unless module_line
  module_path = module_line\gmatch('module (.+)')!
  return unless module_path
  package_line = buffer.lines[1]
  package_name = package_line\gmatch('package (.+)')!
  return unless package_name
  package_path = buffer.file.parent\relative_to_parent(project.root)
  return project.root, "#{module_path}/#{package_path}"

register_inspections = ->
  inspection.register
    name: 'staticcheck'
    factory: (buffer) ->
      cwd, package = get_go_package buffer
      return nil if not package
      {
        cmd: "staticcheck #{package}",
        type: 'warning',
        working_directory: cwd
        is_available: -> sys.find_executable('staticcheck'), "`staticcheck` command not found"
      }

  inspection.register
    name: 'govet'
    factory: (buffer) ->
      cwd, package = get_go_package buffer
      return nil if not package
      {
        cmd: package and "go vet #{package}",
        type: 'error',
        working_directory: cwd
        is_available: -> sys.find_executable('go'), "`go` command not found"
      }

register_mode = ->
  mode_reg =
    name: 'go'
    aliases: 'golang'
    extensions: 'go'
    create: -> bundle_load('go_mode')
    parent: 'curly_mode'

  mode.register mode_reg

register_commands = ->
  command.register
    name: 'go-fmt',
    description: 'Run go fmt on the current buffer and reload if reformatted'
    handler: ->
      buffer = app.editor.buffer
      if buffer.mode.name != 'go'
        log.error 'Buffer is not a go mode buffer'
        return
      fmt buffer

register_mode!
register_commands!
register_inspections!

with config
  .define
    name: 'go_fmt_on_save'
    description: 'Whether to run gofmt when go files are saved'
    default: true
    type_of: 'boolean'

  .define
    name: 'go_fmt_command'
    description: 'Command to run for go-fmt'
    default: 'gofmt'
    scope: 'global'

  .define
    name: 'go_complete'
    description: 'Whether to use gocode completions in go mode'
    default: true
    type_of: 'boolean'

  .define
    name: 'gogetdoc_path',
    description: 'Path to gogetdoc executable'
    default: 'gogetdoc'
    scope: 'global'

unload = ->
  mode.unregister 'go'
  command.unregister 'go-fmt'
  inspection.unregister 'golint'
  inspection.unregister 'gotoolvet'

return {
  info:
    author: 'Copyright 2016-2018 The Howl Developers'
    description: 'Go language support'
    license: 'MIT'
  :unload
}
