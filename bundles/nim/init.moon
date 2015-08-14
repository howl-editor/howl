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
    unless howl.app.editor.buffer.file
      error "No file associated with current buffer."

    exe = howl.app.editor.buffer.config.nim_executable or 'nim'
    unless howl.io.File(exe).exists
      error "Cannot find nim_executable '#{exe}' - please define a valid config.nim_executable."

    howl.command.run "exec #{exe} c -r " .. howl.app.editor.buffer.file.basename

unload = -> howl.mode.unregister 'nim'

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
