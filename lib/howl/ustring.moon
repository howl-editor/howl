import const_char_p from howl.cdefs

ffi = require 'ffi'
import C from ffi

ffi.cdef [[
  glong g_utf8_strlen(const gchar *str, gssize len);
  gchar * g_utf8_strdown(const gchar *str, gssize len);
  gchar * g_utf8_strup(const gchar *str, gssize len);
  gchar * g_utf8_strreverse(const gchar *str, gssize len);
  gint g_utf8_collate(const gchar *str1, const gchar *str2);
  int strncmp(const char *s1, const char *s2, size_t n);
  void g_free(gpointer mem);
  size_t strlen(const char *s);
]]

ustring = ffi.typeof [[
  struct {
    const gchar *ptr;
    size_t size;
    size_t _len;
  }
]]

u = (ptr_or_string, size) ->
  if type(ptr_or_string) == 'string'
    return ustring const_char_p(ptr_or_string), #ptr_or_string
  else
    return ustring ptr_or_string, size or C.strlen ptr_or_string

gc_ptr = (ptr) -> ffi.gc ptr, C.g_free

to_s = (u) -> ffi.string u.ptr, u.size

to_ptr = (s) ->
  if type(s) == 'string'
    const_char_p s
  else
    s.ptr

methods = {
  lower: => u gc_ptr C.g_utf8_strdown @ptr, @size
  upper: => u gc_ptr C.g_utf8_strup @ptr, @size
  reverse: => u gc_ptr ffi.C.g_utf8_strreverse @ptr, @size
  len: (...) => @size
}

for m in *{
  'find'
  'format'
  'rep'
  'gsub'
  'gmatch'
  'match'
  'byte'
  'sub'
}
  methods[m] = (...) => string[m] to_s(self), ...

ffi.metatype ustring, {
  __tostring: => ffi.string @ptr, @size
  __len: => @size
  __concat: (a, b) -> return u tostring(a) .. tostring(b)

  __eq: (a, b) ->
    a, b = b, a if ffi.istype ustring, b

    if ffi.istype ustring, b
      return a.size == b.size and 0 == C.strncmp a.ptr, b.ptr, a.size
    elseif type(b) == 'string'
      return a.size == #b and 0 == C.strncmp a.ptr, const_char_p(b), a.size

    false

  __lt: (a, b) ->
    0 >= C.g_utf8_collate to_ptr(a), to_ptr(b)

  __index: (k) =>
    if k == 'ulen'
      @_len = C.g_utf8_strlen @ptr, @size unless @_len > 0
      @_len
    else
      return methods[k]
}

return u