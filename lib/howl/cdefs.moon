-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'

ffi.cdef [[
  typedef char gchar;
  typedef long glong;
  typedef int gint;
  typedef gint gboolean;
  typedef signed long gssize;
  typedef void* gpointer;
  typedef int32_t GQuark;

  typedef struct {
    GQuark  domain;
    gint    code;
    gchar * message;
  } GError;

  void *malloc(size_t size);
  void free(void *ptr);
  void g_free(gpointer mem);

  glong   g_utf8_pointer_to_offset(const gchar *str, const gchar *pos);
  gchar * g_utf8_offset_to_pointer(const gchar *str, glong offset);
  gchar * g_utf8_find_next_char   (const gchar *p, const gchar *end);
]]

return {
  const_char_p: ffi.typeof 'const char *'
  char_p: ffi.typeof 'char *'
  char_arr: ffi.typeof 'char[?]'
  gint: ffi.typeof 'gint'
  GError: ffi.typeof 'GError'
}
