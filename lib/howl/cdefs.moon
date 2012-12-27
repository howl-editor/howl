ffi = require 'ffi'

ffi.cdef [[
  typedef char gchar;
  typedef long glong;
  typedef int gint;
  typedef signed long gssize;
  typedef void* gpointer;

  void *malloc(size_t size);
  void free(void *ptr);
]]

return {
  const_char_p: ffi.typeof 'const char *'
  char_p: ffi.typeof 'char *'
  char_arr: ffi.typeof('char[?]')
}
