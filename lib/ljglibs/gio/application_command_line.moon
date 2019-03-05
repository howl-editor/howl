-- Copyright 2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gio'
core = require 'ljglibs.core'

C = ffi.C

core.define 'GApplicationCommandLine < GObject', {

  properties: {
    is_remote: 'gboolean'

    arguments: =>
      argc = ffi.new 'int[1]'
      arr = C.g_application_command_line_get_arguments @, argc
      args = {}
      for i = 0, argc[0] - 1
        args[#args + 1] = ffi.string arr[i]

      C.g_strfreev arr
      args

    cwd: =>
      ffi.string C.g_application_command_line_get_cwd @
  }
}
