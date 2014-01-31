-- Copyright 2013-2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

require 'ljglibs.cdefs.glib'
ffi = require 'ffi'
C, ffi_string = ffi.C, ffi.string

unpack = table.unpack

g_string = (ptr) ->
  return nil if ptr == nil
  s = ffi_string ptr
  C.g_free ptr
  s

return {
  :g_string

  catch_error: (f, ...) ->
    err = ffi.new 'GError *[1]'
    n = select '#', ...
    args = {...}
    args[n + 1] = err
    ret = f unpack(args, 1, n + 1)

    if err[0] != nil
      err_s = ffi_string err[0].message
      code = err[0].code
      C.g_error_free err[0]
      error "#{err_s} (code: #{code})", 2

    ret

  get_current_dir: -> g_string C.g_get_current_dir!
}
