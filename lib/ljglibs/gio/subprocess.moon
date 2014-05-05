-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

glib = require 'ljglibs.glib'

return glib.unavailable_module('Subprocess') unless glib.check_version 2, 40, 0

ffi = require 'ffi'
require 'ljglibs.cdefs.gio'
require 'ljglibs.gio.input_stream'
require 'ljglibs.gio.output_stream'

gio = require 'ljglibs.gio'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
callbacks = require 'ljglibs.callbacks'

import ref_ptr from gobject
import get_error, catch_error, Bytes from glib
C = ffi.C
ffi_string, ffi_cast = ffi.string, ffi.cast

core.define 'GSubprocess < GObject', {
  constants: {
    prefix: 'G_SUBPROCESS_'

    -- GSubprocessFlags
    'FLAGS_NONE',
    'FLAGS_STDIN_PIPE',
    'FLAGS_STDIN_INHERIT',
    'FLAGS_STDOUT_PIPE',
    'FLAGS_STDOUT_SILENCE',
    'FLAGS_STDERR_PIPE',
    'FLAGS_STDERR_SILENCE',
    'FLAGS_STDERR_MERGE',
    'FLAGS_INHERIT_FDS',
  }

  properties: {
    succesful: => C.g_subprocess_get_successful(@) != 0
    exit_status: => tonumber C.g_subprocess_get_exit_status @
    if_signaled: => C.g_subprocess_get_if_signaled(@) != 0
    if_exited: => C.g_subprocess_get_if_exited(@) != 0
    term_sig: => tonumber C.g_subprocess_get_term_sig @
    identifer: => C.g_subprocess_get_identifier @

    stdin_pipe: => ref_ptr C.g_subprocess_get_stdin_pipe @
    stdout_pipe: => ref_ptr C.g_subprocess_get_stdout_pipe @
    stderr_pipe: => ref_ptr C.g_subprocess_get_stderr_pipe @
  }

  wait: => catch_error(C.g_subprocess_wait, @, nil) != 0
  wait_check: => catch_error(C.g_subprocess_wait_check, @, nil) != 0
  send_signal: (signal) => C.g_subprocess_send_signal @, signal
  force_exit: => C.g_subprocess_force_exit @

  wait_async: (callback) =>
    local handle

    handler = (source, res) ->
      callbacks.unregister handle
      callback ffi_cast('GAsyncResult *', res)

    handle = callbacks.register handler, 'process-wait-async'
    C.g_subprocess_wait_async @, nil, gio.async_ready_callback, callbacks.cast_arg(handle.id)

  wait_finish: (result) =>
    catch_error(C.g_subprocess_wait_finish, @, result) != 0

  communicate: (opts) =>
    @_communicate C.g_subprocess_communicate, opts

  communicate_utf8: (opts) =>
    @_communicate C.g_subprocess_communicate_utf8, opts

  communicate_async: (opts = {}, callback) =>
    start_f = C.g_subprocess_communicate_async
    finish_f = C.g_subprocess_communicate_finish
    @_communicate_async start_f, finish_f, opts, callback

  communicate_async_utf8: (opts = {}, callback) =>
    start_f = C.g_subprocess_communicate_async_utf8
    finish_f = C.g_subprocess_communicate_utf8_finish
    @_communicate_async start_f, finish_f, opts, callback

  _communicate: (f, opts = {}) =>
    stdin_b = opts.stdin and Bytes(opts.stdin) or nil
    out_pointers = ffi.new 'GBytes *[2]'
    out_bytes = opts.capture_stdout and out_pointers or nil
    err_bytes = opts.capture_stderr and out_pointers + 1 or nil
    catch_error f, @, stdin_b, nil, out_bytes, err_bytes
    out = Bytes.gc_ptr out_pointers[0]
    err = Bytes.gc_ptr out_pointers[1]
    out and out.data, err and err.data

  _communicate_async: (f, finish_f, opts = {}, callback) =>
    local handle

    handler = (source, res) ->
      callbacks.unregister handle
      res = ffi_cast('GAsyncResult *', res)
      out_pointers = ffi.new 'GBytes *[2]'
      out_bytes = opts.capture_stdout and out_pointers or nil
      err_bytes = opts.capture_stderr and out_pointers + 1 or nil
      status, err_s, err_code = get_error(finish_f, @, res, out_bytes, err_bytes)
      if status
        out = Bytes.gc_ptr out_pointers[0]
        err = Bytes.gc_ptr out_pointers[1]
        callback true, out and out.data, err and err.data
      else
        callback false, err_s, err_code

    handle = callbacks.register handler, 'process-communicate_async'
    stdin_b = opts.stdin and Bytes(opts.stdin) or nil
    f @, stdin_b, nil, gio.async_ready_callback, callbacks.cast_arg(handle.id)

},  (t, flags = t.FLAGS_NONE, ...) ->
  args = table.pack ...
  c_args = ffi.new 'const gchar *[?]', args.n + 1
  for i = 1, args.n
    c_args[i - 1] = args[i]

  c_args[args.n] = nil

  ref_ptr catch_error(C.g_subprocess_newv, c_args, core.parse_flags('G_SUBPROCESS_', flags))
