-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.glib'
core = require 'ljglibs.core'
glib = require 'ljglibs.glib'
import g_string, catch_error from glib

C, ffi_string, ffi_gc = ffi.C, ffi.string, ffi.gc
{:parse_flags} = core

core.define 'GMatchInfo', {
  properties: {
    match_count: => C.g_match_info_get_match_count @
    is_partial_match: => C.g_match_info_is_partial_match(@) != 0
  }

  matches: =>  C.g_match_info_matches(@) != 0
  next: => catch_error(C.g_match_info_next, @) != 0
  fetch: (match_num) => g_string C.g_match_info_fetch @, match_num

  fetch_pos: (match_num) =>
    start_pos = ffi.new 'gint[1]'
    end_pos = ffi.new 'gint[1]'

    if C.g_match_info_fetch_pos(@, match_num, start_pos, end_pos) == 0
      return nil, "No group found for match_num #{match_num}"

    start_pos[0], end_pos[0]
}

core.define 'GRegex', {
  constants: {
    prefix: 'G_REGEX_'

    -- Compilation flags
    'CASELESS',
    'MULTILINE',
    'DOTALL',
    'EXTENDED',
    'ANCHORED',
    'DOLLAR_ENDONLY',
    'UNGREEDY',
    'RAW',
    'NO_AUTO_CAPTURE',
    'OPTIMIZE',
    'FIRSTLINE',
    'DUPNAMES',
    'NEWLINE_CR',
    'NEWLINE_LF',
    'NEWLINE_CRLF',
    'NEWLINE_ANYCRLF',
    'BSR_ANYCRLF',
    'JAVASCRIPT_COMPAT',

    -- Match flags
    'MATCH_ANCHORED',
    'MATCH_NOTBOL',
    'MATCH_NOTEOL',
    'MATCH_NOTEMPTY',
    'MATCH_PARTIAL',
    'MATCH_NEWLINE_CR',
    'MATCH_NEWLINE_LF',
    'MATCH_NEWLINE_CRLF',
    'MATCH_NEWLINE_ANY',
    'MATCH_NEWLINE_ANYCRLF',
    'MATCH_BSR_ANYCRLF',
    'MATCH_BSR_ANY',
    'MATCH_PARTIAL_SOFT',
    'MATCH_PARTIAL_HARD',
    'MATCH_NOTEMPTY_ATSTART',
  }

  escape_string: (s) -> g_string C.g_regex_escape_string(s, #s)

  properties: {
    pattern: => ffi_string C.g_regex_get_pattern @
    capture_count: => C.g_regex_get_capture_count @
  }

  match: (s, match_options = 0) =>
    if match_options != 0
      match_options = parse_flags 'G_REGEX_', match_options
    C.g_regex_match(@, s, match_options, nil) != 0

  match_with_info: (s, match_options = 0) =>
    if match_options != 0
      match_options = parse_flags 'G_REGEX_', match_options
    mi = ffi.new 'GMatchInfo *[1]'
    matched = C.g_regex_match(@, s, match_options, mi) != 0
    info = mi[0]
    ffi_gc info, C.g_match_info_free
    matched and info or nil

  match_full: (s, len, start_position, match_options = 0) =>
    len or= #s
    start_position or= 1
    if match_options != 0
      match_options = parse_flags 'G_REGEX_', match_options
    catch_error(
      C.g_regex_match_full,
      @,
      s,
      len,
      start_position,
      match_options,
      nil
    ) != 0

  match_full_with_info: (s, len, start_position, match_options = 0) =>
    len or= #s
    start_position or= 1
    if match_options != 0
      match_options = parse_flags 'G_REGEX_', match_options
    mi = ffi.new 'GMatchInfo *[1]'
    matched = catch_error(
      C.g_regex_match_full,
      @,
      s,
      len,
      start_position,
      match_options,
      mi
    ) != 0
    info = mi[0]
    ffi_gc info, C.g_match_info_free
    matched and info or nil

  meta: {
    __tostring: => @pattern
    __plain_constructor: true
  }

}, (def, pattern, compile_options = 0, match_options = 0) ->
  err = ffi.new 'GError *[1]'
  if compile_options != 0
    compile_options = parse_flags 'G_REGEX_', compile_options
  if match_options != 0
    match_options = parse_flags 'G_REGEX_', match_options
  regex = C.g_regex_new pattern, compile_options, match_options, err

  if err[0] != nil
    err_s = ffi.string err[0].message
    code = err[0].code
    C.g_error_free err[0]
    error "#{err_s} (code: #{code})", 2

  ffi_gc regex, C.g_regex_unref
  return regex
