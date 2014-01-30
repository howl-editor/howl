-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'
require 'ljglibs.cdefs.glib'

ffi.cdef [[
  typedef void GCancellable;

  /* GFileInfo */
  typedef struct GFileInfo GFileInfo;

  typedef enum {
    G_FILE_TYPE_UNKNOWN = 0,
    G_FILE_TYPE_REGULAR,
    G_FILE_TYPE_DIRECTORY,
    G_FILE_TYPE_SYMBOLIC_LINK,
    G_FILE_TYPE_SPECIAL, /* socket, fifo, blockdev, chardev */
    G_FILE_TYPE_SHORTCUT,
    G_FILE_TYPE_MOUNTABLE
  } GFileType;

  const char *        g_file_info_get_name                (GFileInfo *info);
  GFileType           g_file_info_get_file_type           (GFileInfo *info);
  gboolean            g_file_info_get_is_hidden           (GFileInfo *info);
  gboolean            g_file_info_get_is_backup           (GFileInfo *info);
  gboolean            g_file_info_get_is_symlink          (GFileInfo *info);
  goffset             g_file_info_get_size                (GFileInfo *info);
  const char *        g_file_info_get_etag                (GFileInfo *info);

  const char * g_file_info_get_attribute_string (GFileInfo *info, const char *attribute);
  gboolean g_file_info_get_attribute_boolean (GFileInfo *info, const char *attribute);
  guint64 g_file_info_get_attribute_uint64 (GFileInfo *info, const char *attribute);

  /* GFileEnumerator */
  typedef struct GFileEnumerator GFileEnumerator;

  GFileInfo * g_file_enumerator_next_file (GFileEnumerator *enumerator,
                                           GCancellable *cancellable,
                                           GError **error);

  gboolean g_file_enumerator_close (GFileEnumerator *enumerator,
                                    GCancellable *cancellable,
                                    GError **error);
  /* GFile */
  typedef struct {} GFile;

  typedef enum {
    G_FILE_QUERY_INFO_NONE              = 0,
    G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS = (1 << 0)   /*< nick=nofollow-symlinks >*/
  } GFileQueryInfoFlags;

  GFile * g_file_new_for_path (const char *path);

  char * g_file_get_basename (GFile *file);
  char * g_file_get_uri (GFile *file);
  char * g_file_get_path (GFile *file);
  GFile * g_file_get_parent (GFile *file);
  char * g_file_get_relative_path (GFile *parent, GFile *descendant);
  gboolean g_file_query_exists (GFile *file, GCancellable *cancellable);
  gboolean g_file_has_parent (GFile *file, GFile *parent);

  GFileInfo * g_file_query_info (GFile *file,
                                const char *attributes,
                                GFileQueryInfoFlags flags,
                                GCancellable *cancellable,
                                GError **error);

  gboolean g_file_load_contents (GFile *file,
                                 GCancellable *cancellable,
                                 char **contents,
                                 gsize *length,
                                 char **etag_out,
                                 GError **error);

  GFileEnumerator * g_file_enumerate_children (GFile *file,
                                               const char *attributes,
                                               GFileQueryInfoFlags flags,
                                               GCancellable *cancellable,
                                               GError **error);

  GFile * g_file_get_child (GFile *file, const char *name);

  gboolean g_file_make_directory (GFile *file,
                                  GCancellable *cancellable,
                                  GError **error);

  gboolean g_file_make_directory_with_parents (GFile *file,
                                               GCancellable *cancellable,
                                               GError **error);

  gboolean g_file_delete (GFile *file,
                          GCancellable *cancellable,
                          GError **error);


  /* GApplication */
  typedef struct {} GApplication;

  typedef enum {
    G_APPLICATION_FLAGS_NONE,
    G_APPLICATION_IS_SERVICE  =          (1 << 0),
    G_APPLICATION_IS_LAUNCHER =          (1 << 1),

    G_APPLICATION_HANDLES_OPEN =         (1 << 2),
    G_APPLICATION_HANDLES_COMMAND_LINE = (1 << 3),
    G_APPLICATION_SEND_ENVIRONMENT    =  (1 << 4),

    G_APPLICATION_NON_UNIQUE =           (1 << 5)
  } GApplicationFlags;

  GApplication * g_application_new (const gchar *application_id,
                                    GApplicationFlags flags);

  const gchar * g_application_get_application_id (GApplication *application);
  void          g_application_set_application_id (GApplication *application,
                                                  const gchar *application_id);

  GApplicationFlags g_application_get_flags (GApplication *application);
  void              g_application_set_flags (GApplication *application,
                                             GApplicationFlags flags);

  gboolean g_application_register (GApplication *application,
                                   GCancellable *cancellable,
                                   GError **error);

  int g_application_run (GApplication *application, int argc, char **argv);
  void g_application_release (GApplication *application);
  void g_application_quit (GApplication *application);

]]
