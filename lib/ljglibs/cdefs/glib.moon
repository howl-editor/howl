-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'

ffi.cdef [[
  typedef char          gchar;
  typedef long          glong;
  typedef unsigned long gulong;
  typedef int           gint;
  typedef unsigned int  guint;
  typedef int8_t        gint8;
  typedef int16_t       gint16;
  typedef int32_t       gint32;
  typedef int64_t       gint64;
  typedef uint8_t       guint8;
  typedef uint16_t      guint16;
  typedef uint32_t      guint32;
  typedef uint64_t      guint64;
  typedef gint          gboolean;
  typedef unsigned long gsize;
  typedef signed long   gssize;
  typedef void *        gpointer;
  typedef int32_t       GQuark;
  typedef guint32       gunichar;
  typedef guint64       guint64;
  typedef gint64        goffset;
  typedef double        gdouble;
  typedef float         gfloat;
  typedef const void *  gconstpointer;


  /* version definitions */
  extern const guint glib_major_version;
  extern const guint glib_minor_version;
  extern const guint glib_micro_version;
  extern const guint glib_binary_age;
  extern const guint glib_interface_age;

  const gchar * glib_check_version (guint required_major,
                                    guint required_minor,
                                    guint required_micro);
  /* GError definitions */
  typedef struct {
    GQuark  domain;
    gint    code;
    gchar * message;
  } GError;

  void g_error_free (GError *error);

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


  /* utf8 helper functions */
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

  /* Callback definitions */
  typedef void (*GCallback) (void);

  typedef void (*GVCallback1) (gpointer);
  typedef void (*GVCallback2) (gpointer, gpointer);
  typedef void (*GVCallback3) (gpointer, gpointer, gpointer);
  typedef void (*GVCallback4) (gpointer, gpointer, gpointer, gpointer);
  typedef void (*GVCallback5) (gpointer, gpointer, gpointer, gpointer, gpointer);
  typedef void (*GVCallback6) (gpointer, gpointer, gpointer, gpointer, gpointer, gpointer);
  typedef void (*GVCallback7) (gpointer, gpointer, gpointer, gpointer, gpointer, gpointer, gpointer);

  typedef gboolean (*GBCallback1) (gpointer);
  typedef gboolean (*GBCallback2) (gpointer, gpointer);
  typedef gboolean (*GBCallback3) (gpointer, gpointer, gpointer);
  typedef gboolean (*GBCallback4) (gpointer, gpointer, gpointer, gpointer);
  typedef gboolean (*GBCallback5) (gpointer, gpointer, gpointer, gpointer, gpointer);
  typedef gboolean (*GBCallback6) (gpointer, gpointer, gpointer, gpointer, gpointer, gpointer);
  typedef gboolean (*GBCallback7) (gpointer, gpointer, gpointer, gpointer, gpointer, gpointer, gpointer);

  typedef gboolean (*GCallback1) (gpointer);
  typedef gboolean (*GCallback2) (gpointer, gpointer);
  typedef gboolean (*GCallback3) (gpointer, gpointer, gpointer);
  typedef gboolean (*GCallback4) (gpointer, gpointer, gpointer, gpointer);

  /* main loop */
  typedef GCallback1 GSourceFunc;
  typedef GCallback1 GDestroyNotify;
  typedef gpointer GMainContext;

  GMainContext g_main_context_default(void);
  gboolean g_main_context_iteration(GMainContext *context, gboolean may_block);

  guint g_idle_add_full(gint priority,
                        GSourceFunc function,
                        gpointer data,
                        GDestroyNotify notify);

  guint g_timeout_add_full(gint priority,
                           guint interval,
                           GSourceFunc function,
                           gpointer data,
                           GDestroyNotify notify);

  enum GPriority {
    G_PRIORITY_HIGH = -100,
    G_PRIORITY_DEFAULT = 0,
    G_PRIORITY_HIGH_IDLE = 100,
    G_PRIORITY_DEFAULT_IDLE = 200,
    G_PRIORITY_LOW = 300
  };

  /* GRegex */
  typedef enum {
    G_REGEX_CASELESS          = 1 << 0,
    G_REGEX_MULTILINE         = 1 << 1,
    G_REGEX_DOTALL            = 1 << 2,
    G_REGEX_EXTENDED          = 1 << 3,
    G_REGEX_ANCHORED          = 1 << 4,
    G_REGEX_DOLLAR_ENDONLY    = 1 << 5,
    G_REGEX_UNGREEDY          = 1 << 9,
    G_REGEX_RAW               = 1 << 11,
    G_REGEX_NO_AUTO_CAPTURE   = 1 << 12,
    G_REGEX_OPTIMIZE          = 1 << 13,
    G_REGEX_FIRSTLINE         = 1 << 18,
    G_REGEX_DUPNAMES          = 1 << 19,
    G_REGEX_NEWLINE_CR        = 1 << 20,
    G_REGEX_NEWLINE_LF        = 1 << 21,
    G_REGEX_NEWLINE_CRLF      = G_REGEX_NEWLINE_CR | G_REGEX_NEWLINE_LF,
    G_REGEX_NEWLINE_ANYCRLF   = G_REGEX_NEWLINE_CR | 1 << 22,
    G_REGEX_BSR_ANYCRLF       = 1 << 23,
    G_REGEX_JAVASCRIPT_COMPAT = 1 << 25
  } GRegexCompileFlags;

  typedef enum {
    G_REGEX_MATCH_ANCHORED         = 1 << 4,
    G_REGEX_MATCH_NOTBOL           = 1 << 7,
    G_REGEX_MATCH_NOTEOL           = 1 << 8,
    G_REGEX_MATCH_NOTEMPTY         = 1 << 10,
    G_REGEX_MATCH_PARTIAL          = 1 << 15,
    G_REGEX_MATCH_NEWLINE_CR       = 1 << 20,
    G_REGEX_MATCH_NEWLINE_LF       = 1 << 21,
    G_REGEX_MATCH_NEWLINE_CRLF     = G_REGEX_MATCH_NEWLINE_CR | G_REGEX_MATCH_NEWLINE_LF,
    G_REGEX_MATCH_NEWLINE_ANY      = 1 << 22,
    G_REGEX_MATCH_NEWLINE_ANYCRLF  = G_REGEX_MATCH_NEWLINE_CR | G_REGEX_MATCH_NEWLINE_ANY,
    G_REGEX_MATCH_BSR_ANYCRLF      = 1 << 23,
    G_REGEX_MATCH_BSR_ANY          = 1 << 24,
    G_REGEX_MATCH_PARTIAL_SOFT     = G_REGEX_MATCH_PARTIAL,
    G_REGEX_MATCH_PARTIAL_HARD     = 1 << 27,
    G_REGEX_MATCH_NOTEMPTY_ATSTART = 1 << 28
  } GRegexMatchFlags;

  typedef struct {} GMatchInfo;

  gint      g_match_info_get_match_count(const GMatchInfo *match_info);
  gboolean  g_match_info_matches        (const GMatchInfo *match_info);
  gboolean  g_match_info_next           (GMatchInfo *match_info, GError **error);
  gchar *   g_match_info_fetch          (const GMatchInfo *match_info, gint match_num);
  void      g_match_info_unref          (GMatchInfo *match_info);
  gboolean  g_match_info_fetch_pos      (const GMatchInfo *match_info,
                                         gint match_num,
                                         gint *start_pos,
                                         gint *end_pos);

  typedef struct {} GRegex;

  GRegex *      g_regex_new               (const gchar *pattern,
                                           GRegexCompileFlags compile_options,
                                           GRegexMatchFlags match_options,
                                           GError **error);
  void          g_regex_unref             (GRegex *regex);
  const gchar * g_regex_get_pattern       (const GRegex *regex);
  gint          g_regex_get_capture_count (const GRegex *regex);
  gboolean      g_regex_match             (const GRegex *regex,
                                           const gchar *string,
                                           GRegexMatchFlags match_options,
                                           GMatchInfo **match_info);
  gchar *       g_regex_escape_string     (const gchar *string, gint length);

  /* GList */
  typedef struct {} GList;

  GList * g_list_append (GList *list, gpointer data);
  GList * g_list_prepend (GList *list, gpointer data);
  GList * g_list_insert (GList *list, gpointer data, gint position);
  GList * g_list_remove (GList *list, gconstpointer data);
  GList * g_list_remove_all (GList *list, gconstpointer data);
  void g_list_free (GList *list);
  guint g_list_length (GList *list);
  GList * g_list_nth (GList *list, guint n);
  gpointer g_list_nth_data (GList *list, guint n);

  /* GBytes */
  typedef struct {} GBytes;
  GBytes * g_bytes_new_static (gconstpointer data, gsize size);
  GBytes * g_bytes_new (gconstpointer data, gsize size);
  gsize g_bytes_get_size (GBytes *bytes);
  gconstpointer g_bytes_get_data (GBytes *bytes, gsize *size);
  GBytes * g_bytes_ref (GBytes *bytes);
  void g_bytes_unref (GBytes *bytes);

  /* Utility functions */
  const gchar * g_get_home_dir (void);
  gchar * g_get_current_dir (void);
  gchar * g_strndup (const gchar *str, gsize n);
  void g_free(gpointer mem);

  /* Process spawning */
  typedef enum {
    G_SPAWN_DEFAULT                = 0,
    G_SPAWN_LEAVE_DESCRIPTORS_OPEN = 1 << 0,
    G_SPAWN_DO_NOT_REAP_CHILD      = 1 << 1,
    /* look for argv[0] in the path i.e. use execvp() */
    G_SPAWN_SEARCH_PATH            = 1 << 2,
    /* Dump output to /dev/null */
    G_SPAWN_STDOUT_TO_DEV_NULL     = 1 << 3,
    G_SPAWN_STDERR_TO_DEV_NULL     = 1 << 4,
    G_SPAWN_CHILD_INHERITS_STDIN   = 1 << 5,
    G_SPAWN_FILE_AND_ARGV_ZERO     = 1 << 6,
    G_SPAWN_SEARCH_PATH_FROM_ENVP  = 1 << 7
  } GSpawnFlags;

  typedef int GPid;
  typedef void (*GSpawnChildSetupFunc) (gpointer user_data);

  gboolean g_spawn_async_with_pipes (const gchar *working_directory,
                                     gchar **argv,
                                     gchar **envp,
                                     GSpawnFlags flags,
                                     GSpawnChildSetupFunc child_setup,
                                     gpointer user_data,
                                     GPid *child_pid,
                                     gint *standard_input,
                                     gint *standard_output,
                                     gint *standard_error,
                                     GError **error);

  void g_spawn_close_pid (GPid pid);
]]
