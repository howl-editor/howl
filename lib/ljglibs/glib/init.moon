-- Copyright 2013-2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)
core = require 'ljglibs.core'

require 'ljglibs.cdefs.glib'
ffi = require 'ffi'
C, ffi_string, ffi_gc, ffi_new = ffi.C, ffi.string, ffi.gc, ffi.new

unpack = table.unpack

g_string = (ptr) ->
  return nil if ptr == nil
  s = ffi_string ptr
  C.g_free ptr
  s

get_error = (f, ...) ->
  err = ffi.new 'GError *[1]'
  n = select '#', ...
  args = {...}
  args[n + 1] = err
  ret = f unpack(args, 1, n + 1)

  if err[0] != nil
    err_s = ffi_string err[0].message
    code = err[0].code
    C.g_error_free err[0]
    return false, err_s, code

  true, ret

strdup = (s) ->
  return nil unless s
  ffi.gc(C.g_strndup(s, #s), C.g_free)

major_version = tonumber C.glib_major_version
minor_version = tonumber C.glib_minor_version
micro_version = tonumber C.glib_micro_version

core.auto_loading 'glib', {
  :major_version
  :minor_version
  :micro_version

  check_version: (major, minor, micro) ->
    err = C.glib_check_version major, minor, micro
    if err != nil
      return false, ffi_string(err)

    true

  unavailable_module: (name) -> setmetatable {},
    __index: -> error "The #{name} module is not available for glib #{major_version}.#{minor_version}.#{micro_version}", 2

  :g_string
  :get_error
  :strdup

  catch_error: (f, ...) ->
    status, ret, code = get_error f, ...
    error "#{ret} (code: #{code})", 2 unless status
    ret

  get_current_dir: -> g_string C.g_get_current_dir!
  get_home_dir: -> ffi_string C.g_get_home_dir!


  char_p_arr: (t = {}) ->
    arr = ffi_new 'gchar *[?]', #t + 1
    for i = 1, #t
      arr[i - 1] = strdup t[i]

    arr[#t] = nil
    arr
}
