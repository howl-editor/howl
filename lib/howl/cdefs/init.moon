-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'

ffi.cdef [[
  void *malloc(size_t size);
  void free(void *ptr);
  int strncmp(const char *s1, const char *s2, size_t n);
]]

return {
  const_char_p: ffi.typeof 'const char *'
  char_p: ffi.typeof 'char *'
  char_arr: ffi.typeof 'char[?]'

  glib: require 'howl.cdefs.glib'
  gobject: require 'howl.cdefs.gobject'
}
