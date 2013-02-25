import const_char_p from howl.cdefs

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
  void g_free(gpointer mem);
  size_t strlen(const char *s);

  struct ustring {
    gchar *ptr;
    signed long size;
    signed long _len;
  };
]]

DEALLOC_NONE = 0
DEALLOC_G_FREE = 1
DEALLOC_FREE = 2

deallocators = {
  (u) -> C.g_free u.ptr
  (u) -> C.free u.ptr
}

ustring = ffi.typeof 'struct ustring'

u = (ptr_or_string, size, len = -1, deallocator = DEALLOC_G_FREE) ->
  return ptr_or_string if ffi.istype ustring, ptr_or_string

  if type(ptr_or_string) == 'string'
    size = #ptr_or_string
    ptr_or_string = C.g_strndup ptr_or_string, size
    deallocator = DEALLOC_G_FREE

  us = ustring ptr_or_string, size or C.strlen(ptr_or_string), len

  if deallocator
    free_function = deallocators[deallocator]
    ffi.gc us, free_function if free_function

  us

to_s = (u) -> ffi.string u.ptr, u.size

to_ptr = (s) ->
  if type(s) == 'string'
    const_char_p s
  else
    s.ptr

transform_rets = (us, ...) ->
  vals = {...}

  for i = 1, #vals
    val = vals[i]
    t = type(val)

    if t == 'string'
      vals[i] = u val
    elseif t == 'number'
      pos_ptr = us.ptr + val - 1

      -- position may be in the middle of a sequence here, so back up as needed
      while pos_ptr != us.ptr and bit.band(pos_ptr[0], 0xc0) == 0x80
        pos_ptr -= 1

      char_offset = C.g_utf8_pointer_to_offset us.ptr, pos_ptr
      vals[i] = tonumber char_offset + 1

  table.unpack vals

char_to_byte_offset = (us, i) ->
  return nil if i == nil

  len = #us
  if i < 0
    i = len + i
  elseif i > len
    i = len

  i = 1 if i < 1
  (C.g_utf8_offset_to_pointer(us.ptr, i - 1) - us.ptr) + 1 -- convert to byte offset

mod = {
  :DEALLOC_NONE,
  :DEALLOC_G_FREE,
  :DEALLOC_FREE

  is_instance: (v) -> ffi.istype ustring, v

  lower: => u C.g_utf8_strdown(@ptr, @size), @size, @_len
  upper: => u C.g_utf8_strup(@ptr, @size), @size, @_len
  reverse: => u C.g_utf8_strreverse(@ptr, @size), @size, @_len
  format: (...) => u string.format to_s(self), ...
  byte: (...) => string.byte to_s(self), ...

  match: (pattern, init) =>
    return nil if init and init > @len!
    return pattern\match self, init if r.is_instance pattern
    init = char_to_byte_offset self, init
    transform_rets self, string.match to_s(self), tostring(pattern), init

  gmatch: (pattern) =>
    gen = string.gmatch to_s(self), tostring pattern
    -> transform_rets self, gen!

  find: (pattern, init, plain) =>
    return nil if init and init > @len!
    init = char_to_byte_offset self, init
    transform_rets self, string.find to_s(self), tostring(pattern), init, plain

  sub: (i, j = -1) =>
    len = @len!
    i += len + 1 if i < 0
    j += len + 1 if j < 0
    i = 1 if i < 1
    j = len if j > len
    return '' if j < i

    u C.g_utf8_substring(@ptr, i - 1, j), nil, j - i + 1

  len: =>
    @_len = C.g_utf8_strlen @ptr, @size unless @_len >= 0
    tonumber @_len

  rep: (n, sep) =>
    sep = tostring sep if sep
    u string.rep to_s(self), n, sep

  gsub: (pattern, repl, n) =>
    repl = tostring(repl) if ffi.istype ustring, repl
    s, count = string.gsub to_s(self), tostring(pattern), repl, n
    return u(s), count

  byte_offset: (...) =>
    len = @len!
    ptr = @ptr
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
      elseif not @multibyte then append offsets, offset
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

  char_offset: (...) =>
    size = @size
    ptr = @ptr
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
      elseif not @multibyte then append offsets, offset
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
}

properties = {
  multibyte: => @len! != @size
}

ffi.metatype ustring, {
  __tostring: => ffi.string @ptr, @size
  __len: => @len!
  __concat: (a, b) -> return u tostring(a) .. tostring(b)
  __lt: (a, b) -> 0 > C.g_utf8_collate to_ptr(a), to_ptr(b)

  __eq: (a, b) ->
    a, b = b, a if ffi.istype ustring, b

    if ffi.istype ustring, b
      return a.ptr == b.ptr or a.size == b.size and 0 == C.strncmp a.ptr, b.ptr, a.size
    elseif type(b) == 'string'
      return a.size == #b and 0 == C.strncmp a.ptr, const_char_p(b), a.size

    false

  __index: (k) =>
    return @sub k, k if type(k) == 'number'
    return properties[k] self if properties[k]
    return mod[k]
}

-- poor man's system integration (in wait of more efficient runtime integration)
fix_arg = (arg) -> ffi.istype(ustring, arg) and tostring(arg) or arg

lpeg_match = lpeg.match
lpeg.match = (pattern, subject, init) ->  lpeg_match pattern, fix_arg(subject), init

io_open = io.open
io.open = (filename, mode) -> io_open fix_arg(filename), mode

return setmetatable mod, __call: (...) => u ...
