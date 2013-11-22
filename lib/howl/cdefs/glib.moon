-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'
C, ffi_string = ffi.C, ffi.string

ffi.cdef [[
  typedef char          gchar;
  typedef long          glong;
  typedef unsigned long gulong;
  typedef int           gint;
  typedef unsigned int  guint;
  typedef int8_t        gint8;
  typedef int16_t       gint16;
  typedef int32_t       gint32;
  typedef uint8_t       guint8;
  typedef uint16_t      guint16;
  typedef uint32_t      guint32;
  typedef gint          gboolean;
  typedef unsigned long gsize;
  typedef signed long   gssize;
  typedef void *        gpointer;
  typedef int32_t       GQuark;
  typedef guint32       gunichar;

  typedef struct {
    GQuark  domain;
    gint    code;
    gchar * message;
  } GError;

  typedef void    (*GCallback) (void);

  typedef enum {
    GDK_SHIFT_MASK    = 1 << 0,
    GDK_LOCK_MASK     = 1 << 1,
    GDK_CONTROL_MASK  = 1 << 2,
    GDK_MOD1_MASK     = 1 << 3,
    GDK_MOD2_MASK     = 1 << 4,
    GDK_MOD3_MASK     = 1 << 5,
    GDK_MOD4_MASK     = 1 << 6,
    GDK_MOD5_MASK     = 1 << 7,
    GDK_BUTTON1_MASK  = 1 << 8,
    GDK_BUTTON2_MASK  = 1 << 9,
    GDK_BUTTON3_MASK  = 1 << 10,
    GDK_BUTTON4_MASK  = 1 << 11,
    GDK_BUTTON5_MASK  = 1 << 12,
    GDK_SUPER_MASK    = 1 << 26,
    GDK_HYPER_MASK    = 1 << 27,
    GDK_META_MASK     = 1 << 28,

    GDK_RELEASE_MASK  = 1 << 30,

    GDK_MODIFIER_MASK = 0x5c001fff
  } GdkModifierType;

  void g_free(gpointer mem);

  glong   g_utf8_pointer_to_offset(const gchar *str, const gchar *pos);
  gchar * g_utf8_offset_to_pointer(const gchar *str, glong offset);
  gchar * g_utf8_find_next_char   (const gchar *p, const gchar *end);
  glong   g_utf8_strlen(const gchar *str, gssize len);
  gchar * g_utf8_strdown(const gchar *str, gssize len);
  gchar * g_utf8_strup(const gchar *str, gssize len);
  gchar * g_utf8_strreverse(const gchar *str, gssize len);
  gint    g_utf8_collate(const gchar *str1, const gchar *str2);
  gchar * g_utf8_substring(const gchar *str, glong start_pos, glong end_pos);

  gint    g_unichar_to_utf8(gunichar c, gchar *outbuf);
  gchar * g_strndup(const gchar *str, gssize n);

  /* Custom callback definitions */
  typedef gboolean (*GCallback3) (gpointer, gpointer, gpointer);
  typedef gboolean (*GCallback4) (gpointer, gpointer, gpointer, gpointer);
]]

return {
  gint: ffi.typeof 'gint'
  GError: ffi.typeof 'GError'

  g_string: (ptr) ->
    return nil if ptr == nil
    s = ffi_string ptr
    C.g_free ptr
    s

  gchar_arr: ffi.typeof 'gchar[?]'

  GDK_KEY_Return: 0xff0d
}
