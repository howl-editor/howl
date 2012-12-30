import const_char_p from howl.cdefs

ffi = require 'ffi'
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
]]

DEALLOC_NONE = 1
DEALLOC_G_FREE = 1
DEALLOC_FREE = 2

deallocators = {
  (u) -> C.g_free u.ptr
  (u) -> C.free u.ptr
}

ustring = ffi.typeof [[
  struct {
    gchar *ptr;
    signed long size;
    signed long _len;
  }
]]

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
      char_offset = C.g_utf8_pointer_to_offset us.ptr, pos_ptr
      vals[i] = tonumber char_offset + 1

  table.unpack vals

methods = {
  lower: => u C.g_utf8_strdown(@ptr, @size), @size, @_len
  upper: => u C.g_utf8_strup(@ptr, @size), @size, @_len
  reverse: => u C.g_utf8_strreverse(@ptr, @size), @size, @_len

  match: (pattern, init) =>
    transform_rets self, string.match to_s(self), tostring(pattern), init

  gmatch: (pattern) =>
    gen = string.gmatch to_s(self), tostring pattern
    -> transform_rets self, gen!

  find: (pattern, init, plain) =>
    transform_rets self, string.find to_s(self), tostring(pattern), init, plain

  sub: (i, j = -1) =>
    len = tonumber @len!
    i += len + 1 if i < 0
    j += len + 1 if j < 0
    i = 1 if i < 1
    j = len if j > len
    return '' if j < i

    u C.g_utf8_substring(@ptr, i - 1, j), nil, j - i + 1

  len: =>
    @_len = C.g_utf8_strlen @ptr, @size unless @_len >= 0
    tonumber @_len
}

for m in *{
  'format'
  'rep'
  'gsub'
  'byte'
}
  methods[m] = (...) => string[m] to_s(self), ...

properties = {
}

ffi.metatype ustring, {
  __tostring: => ffi.string @ptr, @size
  __len: => @len!
  __concat: (a, b) -> return u tostring(a) .. tostring(b)
  __lt: (a, b) -> 0 >= C.g_utf8_collate to_ptr(a), to_ptr(b)

  __eq: (a, b) ->
    a, b = b, a if ffi.istype ustring, b

    if ffi.istype ustring, b
      return a.size == b.size and 0 == C.strncmp a.ptr, b.ptr, a.size
    elseif type(b) == 'string'
      return a.size == #b and 0 == C.strncmp a.ptr, const_char_p(b), a.size

    false

  __index: (k) =>
    return @sub k, k if type(k) == 'number'
    return properties[k] self if properties[k]
    return methods[k]
}

return setmetatable {
  :DEALLOC_NONE,
  :DEALLOC_G_FREE,
  :DEALLOC_FREE
}, __call: (...) => u ...
