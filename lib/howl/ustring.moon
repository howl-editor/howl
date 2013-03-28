import const_char_p from howl.cdefs
import string, type from _G

ffi = require 'ffi'
bit = require 'bit'

import C from ffi

ffi.cdef [[
  glong g_utf8_strlen(const gchar *str, gssize len);
  gchar * g_utf8_strdown(const gchar *str, gssize len);
  gchar * g_utf8_strup(const gchar *str, gssize len);
  gchar * g_utf8_strreverse(const gchar *str, gssize len);
  gint g_utf8_collate(const gchar *str1, const gchar *str2);
  gchar * g_utf8_substring(const gchar *str, glong start_pos, glong end_pos);
  int strncmp(const char *s1, const char *s2, size_t n);
  gchar * g_strndup(const gchar *str, gssize n);
]]


transform_rets = (s, ...) ->
  vals = {...}
  ptr = const_char_p s

  for i = 1, #vals
    val = vals[i]

    if type(val) == 'number'
      pos_ptr = ptr + val - 1

      -- position may be in the middle of a sequence here, so back up as needed
      while pos_ptr != ptr and bit.band(pos_ptr[0], 0xc0) == 0x80
        pos_ptr -= 1

      char_offset = C.g_utf8_pointer_to_offset ptr, pos_ptr
      vals[i] = tonumber char_offset + 1

  table.unpack vals

ulen = (s) -> tonumber C.g_utf8_strlen const_char_p(s), #s

char_to_byte_offset = (s, i) ->
  return nil if i == nil

  len = ulen s
  if i < 0
    i = len + i
  elseif i > len
    i = len

  i = 1 if i < 1
  ptr = const_char_p(s)
  (C.g_utf8_offset_to_pointer(ptr, i - 1) - ptr) + 1 -- convert to byte offset

byte_offset = (s, ...) ->
    len = ulen s
    ptr = const_char_p s
    multibyte = s.multibyte
    cur_c_offset = 1
    cur_b_offset = 1
    args = {...}
    offsets = {}
    is_table = false

    if type(args[1]) == 'table'
      args = args[1]
      is_table = true

    for offset in *args
      o = offset - cur_c_offset
      if o == 0 then  append offsets, cur_b_offset
      elseif o < 0 then error "Decreasing offset '#{offset}': must be >= than previous offset '#{cur_c_offset}'", 2
      elseif o + cur_c_offset > len + 1 then error "Offset '#{offset}' out of bounds (length = #{len})", 2
      elseif not multibyte then append offsets, offset
      else
        next_ptr = C.g_utf8_offset_to_pointer ptr, o
        cur_b_offset += next_ptr - ptr
        append offsets, cur_b_offset
        ptr = next_ptr
        cur_c_offset = offset

    return if is_table
      offsets
    else
      table.unpack offsets

char_offset = (s, ...) ->
  size = #s
  ptr = const_char_p s
  multibyte = s.multibyte
  cur_c_offset = 1
  cur_b_offset = 1
  args = {...}
  offsets = {}
  is_table = false

  if type(args[1]) == 'table'
    args = args[1]
    is_table = true

  for offset in *args
    o = offset - cur_b_offset
    if o == 0 then  append offsets, cur_c_offset
    elseif o < 0 then error "Decreasing offset '#{offset}': must be >= than previous offset '#{cur_b_offset}'", 2
    elseif o + cur_b_offset > size + 1 then error "Offset '#{offset}' out of bounds (size = #{size})", 2
    elseif not multibyte then append offsets, offset
    else
      next_ptr = ptr + o
      cur_b_offset += next_ptr - ptr
      cur_c_offset += tonumber C.g_utf8_pointer_to_offset ptr, next_ptr
      append offsets, cur_c_offset
      ptr = next_ptr

  return if is_table
    offsets
  else
    table.unpack offsets

usub = (i, j = -1) =>
  len = ulen @
  i += len + 1 if i < 0
  j += len + 1 if j < 0
  i = 1 if i < 1
  j = len if j > len
  return '' if j < i

  ffi.string C.g_utf8_substring(const_char_p(@), i - 1, j)

umatch = (s, pattern, init = 1) ->
  return nil if init and init > ulen s
  return pattern\match s, init if r.is_instance pattern
  init = char_to_byte_offset s, init
  transform_rets s, string.match s, pattern, init

ugmatch = (s, pattern) ->
  return pattern\gmatch(s)if r.is_instance pattern
  gen = string.gmatch s, pattern
  -> transform_rets s, gen!

ufind = (s, pattern, init = 1, plain = false) ->
  return nil if init and init > ulen s
  return pattern\find(s, init) if r.is_instance pattern
  init = char_to_byte_offset s, init
  transform_rets s, string.find s, pattern, init, plain

ucompare = (s1, s2) ->
  C.g_utf8_collate const_char_p(s1), const_char_p(s2)

with string
  .usub = usub
  .umatch = umatch
  .ugmatch = ugmatch
  .ufind = ufind
  .ucompare = ucompare
  .byte_offset = byte_offset
  .char_offset = char_offset

properties = {
  ulen: => ulen @
  multibyte: => ulen(@) != #@
  ulower: => ffi.string C.g_utf8_strdown(const_char_p(@), #@)
  uupper: => ffi.string C.g_utf8_strup(const_char_p(@), #@)
  ureverse: => ffi.string C.g_utf8_strreverse(const_char_p(@), #@)}

getmetatable('').__index = (k) =>
  return usub(@, k, k) if type(k) == 'number'
  return properties[k] self if properties[k]
  rawget string, k
