-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
{ :catch_error, :g_string } = require 'ljglibs.glib'

C, ffi_string, ffi_new = ffi.C, ffi.string, ffi.new
append = table.insert

{
  parse_argv: (command_line) ->
    count = ffi_new 'gint[1]'
    arr = ffi_new 'gchar **[1]'
    catch_error C.g_shell_parse_argv, command_line, count, arr
    argv = {}

    for i = 0, count[0] - 1
      append argv, ffi_string arr[0][i]

    C.g_strfreev arr[0]

    argv

  quote: (s) -> g_string C.g_shell_quote s
  unquote: (s) -> g_string catch_error C.g_shell_unquote, s
}

