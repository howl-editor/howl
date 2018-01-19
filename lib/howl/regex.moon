ffi = require 'ffi'
bit = require 'bit'
GRegex = require 'ljglibs.glib.regex'

import type, tonumber from _G
import const_char_p from howl.cdefs
import C from ffi

{:unpack} = table

do_match = (p, s, init) ->
  s = s\usub init unless init == 1
  return nil unless #s > 0
  ptr = const_char_p s
  info = p\match_with_info s
  return nil unless info
  info, ptr, info.match_count

get_capture = (match_info, index, ptr, fetch_positions = false) ->
  match = match_info\fetch index
  return match unless fetch_positions or #match == 0

  start_pos, end_pos = match_info\fetch_pos index

  return match unless start_pos

  -- negative start_pos indicates an non-matching optional capture
  return nil, 0, 0 if start_pos == -1

  start_ptr = ptr + start_pos
  start_offset = tonumber 1 + C.g_utf8_pointer_to_offset ptr, start_ptr

  end_ptr = ptr + end_pos
  end_offset = tonumber (start_offset - 1) + C.g_utf8_pointer_to_offset start_ptr, end_ptr

  match, start_offset, end_offset

get_captures = (match_info, ptr, matches, start, count, offset = 0) ->
  for i = start, count - 1
    match, start_pos = get_capture match_info, i, ptr
    if match == nil
      match = ''
    else
      match = #match > 0 and match or start_pos + offset
    matches[#matches + 1] = match

properties = {
  pattern: => @re.pattern
  capture_count: => @re.capture_count
}

methods = {

  match: (s, init = 1) =>
    match_info, ptr, count = do_match @re, s, init
    return nil unless match_info

    matches = {}
    start = count > 1 and 1 or 0
    get_captures match_info, ptr, matches, start, count, init - 1
    return unpack matches

  find: (s, init = 1) =>
    match_info, ptr, count = do_match @re, s, init
    return nil unless match_info

    _, start_pos, end_pos = get_capture match_info, 0, ptr, true
    matches = { start_pos + init - 1, end_pos + init - 1 }
    get_captures match_info, ptr, matches, 1, count, init - 1
    return unpack matches

  gmatch: (s) =>
    ptr = const_char_p s
    matches = {}
    pos_matches = {}

    info = @re\match_with_info ptr
    if info

      while info\matches!
        count = info.match_count
        capture_start = count > 1 and 1 or 0
        capture_table = count > 2 and {} or matches

        for i = capture_start, count - 1
          match = info\fetch i

          if #match == 0 -- position capture
            start_pos = info\fetch_pos i
            error 'Failed to fetch match position' unless start_pos
            index = #pos_matches + 1
            pos_matches[index] = start_pos + 1
            match = index

          capture_table[#capture_table + 1] = match

        matches[#matches + 1] = capture_table if matches != capture_table
        info\next!

    has_position_captures = #pos_matches > 0
    pos_matches = s\char_offset pos_matches if has_position_captures

    pos = 0
    ->
      pos += 1
      match = matches[pos]
      return nil unless match
      if type(match) == 'table'
        if has_position_captures
          for i, value in ipairs match
            match[i] = pos_matches[value] if type(value) == 'number'

        unpack match
      else
        if has_position_captures and type(match) == 'number' then pos_matches[match] else match

  test: (s) =>
    @re\match s

}

mt = {
  __index: (k) =>
    return methods[k] if methods[k]
    return properties[k] self if properties[k]

  __tostring: => @re.pattern
  __type: 'regex'
}

is_instance = (v) -> getmetatable(v) == mt

r = (pattern, compile_options, match_options) ->
  comp_flags = 0

  if compile_options
    for flag in *compile_options
      comp_flags = bit.bor(comp_flags, flag)

  match_flags = 0

  if match_options
    for flag in *match_options
      match_flags = bit.bor(match_flags, flag)

  return pattern if is_instance pattern
  re = GRegex pattern, comp_flags, match_flags
  setmetatable {:re}, mt

return setmetatable {
  escape: (s) -> GRegex.escape_string s
  :r
  :is_instance
}, {
  __call: (...) => r ...
  __index: GRegex
}
