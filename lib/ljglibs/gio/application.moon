-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gio'
glib = require 'ljglibs.glib'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
import gc_ptr from gobject
import catch_error from glib

C = ffi.C
ffi_string = ffi.string

core.define 'GApplication', {
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
    application_id: => ffi_string C.g_application_get_application_id @
  }

  register: => catch_error(C.g_application_register, @, nil) != 0
  release: => C.g_application_release @
  quit: => C.g_application_quit @

},  (t, application_id, flags) ->
  gc_ptr(C.g_application_new application_id, flags)
