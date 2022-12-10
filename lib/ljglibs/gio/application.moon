-- Copyright 2014-2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gio'
glib = require 'ljglibs.glib'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gio.application_command_line'
import gc_ptr, signal, object from gobject
import catch_error from glib

C = ffi.C
ffi_string, ffi_cast = ffi.string, ffi.cast

Application = core.define 'GApplication < GObject', {
  constants: {
    prefix: 'G_APPLICATION_'

    -- GApplicationFlags
    'FLAGS_NONE',
    'IS_SERVICE',
    'IS_LAUNCHER',
    'HANDLES_OPEN',
    'HANDLES_COMMAND_LINE',
    'SEND_ENVIRONMENT',
    'NON_UNIQUE'
  }

  properties: {
    flags: => C.g_application_get_flags @
    application_id: 'gchar*'
    is_registered: 'gboolean'
    is_remote: 'gboolean'
  }

  register: => catch_error(C.g_application_register, @, nil) != 0
  activate: => C.g_application_activate @
  open: (files, hint = '') =>
    file_arr = ffi.new 'GFile *[?]', #files
    for i = 0, #files - 1
      file_arr[i] = files[i + 1]

    C.g_application_open @, file_arr, #files, hint

  release: => C.g_application_release @
  quit: => C.g_application_quit @

  run: (args) =>
    argv = ffi.new 'char*[?]', #args
    for i = 0, #args - 1
      arg = args[i + 1]
      argv[i] = ffi.new 'char [?]', #arg + 1, arg

    C.g_application_run @, #args, argv

  -- override
  on_open: (handler, ...) =>
    signal.connect @, 'open', (app, files, n_files, hint) ->
      gfiles = {}
      n_files = tonumber ffi_cast('gint', n_files)
      files = ffi_cast 'GFile **', files
      for i = 1, n_files
        gfiles[#gfiles + 1] = gc_ptr object.ref files[i - 1]

      handler app, gfiles, ffi_string hint

  -- on_command_line: (handler, ...) =>
  --   require 'ljglibs.gio.application_command_line'
  --   signal.connect 'int3', @, 'command-line', (app, command_line) ->
  --     exit_code = handler(
  --       ffi_cast('GApplication *', app),
  --       ffi_cast('GApplicationCommandLine *', command_line)
  --     )
  --     exit_code or 0

},  (t, application_id, flags = t.FLAGS_NONE) ->
  gc_ptr(C.g_application_new application_id, flags)

jit.off Application.run

Application
