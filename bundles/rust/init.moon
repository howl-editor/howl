-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.mode.register {
  name: 'rust'
  aliases: 'rs'
  extensions: 'rs'
  create: -> bundle_load('rust_mode')
  parent: 'curly_mode'
}

howl.inspection.register {
  name: 'cargo_check'
  factory: (buffer) ->
    file = buffer.file

    -- TODO: add configs for more cmd options
    -- TODO: make path to cargo a config

    cargo = howl.sys.find_executable 'cargo'

    {
      cmd: { cargo, 'check', '--message-format', 'json' }
      is_available: -> cargo, '`cargo` command not found'
      working_directory: file.parent
      write_stdin: false
      read_stderr: false
      read_stdin: true
      parse: bundle_load('cargo_check_parser')
    }
}

unload = ->
  howl.mode.unregister 'rust'
  howl.inspection.unregister 'cargo_check'

return {
  info:
    author: 'Alejandro Baez https://keybase.io/baez',
    description: 'Rust language support',
    license: 'MIT',
  :unload
}
