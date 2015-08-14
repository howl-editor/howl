-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

mode_reg =
  name: 'nim'
  extensions: 'nim'
  create: bundle_load('nim_mode')

howl.mode.register mode_reg

howl.command.register
  name: 'nim-run'
  description: 'Compile and run the current Nim file'
  handler: ->
    buffer = howl.app.editor.buffer
    unless buffer.file
      error "No file associated with current buffer."

    local nim_exe

    if buffer.config.nim_executable
      path = buffer.config.nim_executable
      nim_exe = howl.io.File(path)
      unless nim_exe.exists
        error "Invalid nim_executable - '#{path}' does not exist."
    else
      nim_exe  = howl.io.File.find_executable 'nim'
      unless nim_exe
        error "Cannot find nim executable - please define config.nim_executable."

    howl.command.run "exec #{nim_exe.path} c -r " .. buffer.file.basename

unload = ->
  howl.mode.unregister 'nim'
  howl.command.unregister 'nim-run'

howl.config.define
  name: 'nim_executable',
  description: 'Path to the nim executable'

return {
  info:
    author: 'Copyright 2015 The Howl Developers',
    description: 'Nim bundle',
    license: 'MIT',
  :unload
}
