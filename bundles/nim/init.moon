mode_reg =
  name: 'nim'
  extensions: 'nim'
  create: bundle_load('nim_mode')

howl.mode.register mode_reg

howl.command.register
  name: 'nim-run'
  description: 'Compile and run the current Nim file'
  handler: ->
    exe = howl.config.nim_executable
    unless exe
      error 'Cannot locate nim executable, please define config.nim_executable.'
    unless howl.io.File(exe).exists
      error "Nonexistent path '#{exe}' - invalid config.nim_executable."
    unless howl.app.editor.buffer.file
      error "No file associated with current buffer."
    howl.command.run "exec #{exe} c -r " .. howl.app.editor.buffer.file.basename

unload = -> howl.mode.unregister 'nim'

howl.config.define
  name: 'nim_executable',
  description: 'Path to the nim executable'

return {
  info:
    author: 'Copyright 2012-2015 The Howl Developers',
    description: 'Nim bundle',
    license: 'MIT',
  :unload
}
