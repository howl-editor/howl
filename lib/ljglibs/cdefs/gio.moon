-- Copyright 2013-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.glib'
require 'ljglibs.cdefs.gobject'

ffi.cdef [[
  typedef void GCancellable;

  /* GAsyncResult */
  typedef struct {} GAsyncResult;

  typedef void (*GAsyncReadyCallback) (GObject *source_object,
                                       GAsyncResult *res,
                                       gpointer user_data);

  /* GInputStream */
  typedef struct {} GInputStream;

  gboolean g_input_stream_close (GInputStream *stream,
                                 GCancellable *cancellable,
                                 GError **error);

  void g_input_stream_close_async (GInputStream *stream,
                                   int io_priority,
                                   GCancellable *cancellable,
                                   GAsyncReadyCallback callback,
                                   gpointer user_data);

  gboolean g_input_stream_close_finish (GInputStream *stream,
                                        GAsyncResult *result,
                                        GError **error);

  gssize g_input_stream_read (GInputStream *stream,
                              void *buffer,
                              gsize count,
                              GCancellable *cancellable,
                              GError **error);

  gboolean g_input_stream_read_all (GInputStream *stream,
                                    void *buffer,
                                    gsize count,
                                    gsize *bytes_read,
                                    GCancellable *cancellable,
                                    GError **error);

  void g_input_stream_read_async (GInputStream *stream,
                                  void *buffer,
                                  gsize count,
                                  int io_priority,
                                  GCancellable *cancellable,
                                  GAsyncReadyCallback callback,
                                  gpointer user_data);

  gssize g_input_stream_read_finish (GInputStream *stream,
                                     GAsyncResult *result,
                                     GError **error);

  gboolean g_input_stream_has_pending (GInputStream *stream);
  gboolean g_input_stream_is_closed (GInputStream *stream);

  /* GOutputStream */
  typedef struct {} GOutputStream;

  gboolean g_output_stream_write_all (GOutputStream *stream,
                                      const void *buffer,
                                      gsize count,
                                      gsize *bytes_written,
                                      GCancellable *cancellable,
                                      GError **error);

  void g_output_stream_write_async (GOutputStream *stream,
                                    const void *buffer,
                                    gsize count,
                                    int io_priority,
                                    GCancellable *cancellable,
                                    GAsyncReadyCallback callback,
                                    gpointer user_data);

  gssize g_output_stream_write_finish (GOutputStream *stream,
                                       GAsyncResult *result,
                                       GError **error);

  gboolean g_output_stream_close (GOutputStream *stream,
                                  GCancellable *cancellable,
                                  GError **error);

  void g_output_stream_close_async (GOutputStream *stream,
                                    int io_priority,
                                    GCancellable *cancellable,
                                    GAsyncReadyCallback callback,
                                    gpointer user_data);

  gboolean g_output_stream_close_finish (GOutputStream *stream,
                                         GAsyncResult *result,
                                         GError **error);

  gboolean g_output_stream_flush (GOutputStream *stream,
                                  GCancellable *cancellable,
                                  GError **error);

  void g_output_stream_flush_async (
    GOutputStream* stream,
    int io_priority,
    GCancellable* cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data
  );

  gboolean g_output_stream_flush_finish (
    GOutputStream* stream,
    GAsyncResult* result,
    GError** error
  );

  gboolean g_output_stream_has_pending (GOutputStream *stream);
  gboolean g_output_stream_is_closed (GOutputStream *stream);
  gboolean g_output_stream_is_closing (GOutputStream *stream);

  /* GUnixInputStream */
  typedef struct {} GUnixInputStream;
  GUnixInputStream * g_unix_input_stream_new (gint fd, gboolean close_fd);

  /* GUnixOutputStream */
  typedef struct {} GUnixOutputStream;
  GUnixOutputStream * g_unix_output_stream_new (gint fd, gboolean close_fd);

  /* GFile and friends */
  typedef struct {} GFileInputStream;
  typedef struct {} GFileOutputStream;
  typedef struct {} GFileInfo;
  typedef struct {} GFile;

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

  GFile * g_file_enumerator_get_child (GFileEnumerator *enumerator,
                                       GFileInfo *info);

  void g_file_enumerator_next_files_async (GFileEnumerator *enumerator,
                                           int num_files,
                                           int io_priority,
                                           GCancellable *cancellable,
                                           GAsyncReadyCallback callback,
                                           gpointer user_data);

  GList * g_file_enumerator_next_files_finish (GFileEnumerator *enumerator,
                                               GAsyncResult *result,
                                               GError **error);

  void g_file_enumerator_close_async (GFileEnumerator *enumerator,
                                      int io_priority,
                                      GCancellable *cancellable,
                                      GAsyncReadyCallback callback,
                                      gpointer user_data);

  gboolean g_file_enumerator_close_finish (GFileEnumerator *enumerator,
                                           GAsyncResult *result,
                                           GError **error);

  /* GFile */
  typedef enum {
    G_FILE_QUERY_INFO_NONE              = 0,
    G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS = (1 << 0)   /*< nick=nofollow-symlinks >*/
  } GFileQueryInfoFlags;

  typedef enum {
    G_FILE_CREATE_NONE    = 0,
    G_FILE_CREATE_PRIVATE = (1 << 0),
    G_FILE_CREATE_REPLACE_DESTINATION = (1 << 1)
  } GFileCreateFlags;

  typedef enum {
    G_FILE_COPY_NONE                 = 0,          /*< nick=none >*/
    G_FILE_COPY_OVERWRITE            = (1 << 0),
    G_FILE_COPY_BACKUP               = (1 << 1),
    G_FILE_COPY_NOFOLLOW_SYMLINKS    = (1 << 2),
    G_FILE_COPY_ALL_METADATA         = (1 << 3),
    G_FILE_COPY_NO_FALLBACK_FOR_MOVE = (1 << 4),
    G_FILE_COPY_TARGET_DEFAULT_PERMS = (1 << 5)
  } GFileCopyFlags;

  typedef void (*GFileProgressCallback)(goffset current_num_bytes,
                                        goffset total_num_bytes,
                                        gpointer user_data);

  GFile * g_file_new_for_path (const char *path);
  GFile * g_file_new_for_commandline_arg_and_cwd (const gchar *arg,
                                                  const gchar *cwd);

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

  void g_file_enumerate_children_async (GFile *file,
                                        const char *attributes,
                                        GFileQueryInfoFlags flags,
                                        int io_priority,
                                        GCancellable *cancellable,
                                        GAsyncReadyCallback callback,
                                        gpointer user_data);

  GFileEnumerator * g_file_enumerate_children_finish (GFile *file,
                                                      GAsyncResult *res,
                                                      GError **error);

  gboolean g_file_copy (GFile *source, GFile *destination,
                        GFileCopyFlags flags,
                        GCancellable *cancellable,
                        GFileProgressCallback progress_callback,
                        gpointer progress_callback_data,
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

  GFileInputStream * g_file_read (GFile *file,
                                  GCancellable *cancellable,
                                  GError **error);

  GFileOutputStream * g_file_append_to (GFile *file,
                                        GFileCreateFlags flags,
                                        GCancellable *cancellable,
                                        GError **error);

  /* GApplicationCommandLine */
  typedef struct {} GApplicationCommandLine;

  gchar ** g_application_command_line_get_arguments(
    GApplicationCommandLine *cmdline,
    int *argc);

  const gchar * g_application_command_line_get_cwd (GApplicationCommandLine *cmdline);

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
  void g_application_activate (GApplication *application);
  void g_application_open (GApplication *application,
                           GFile **files,
                           gint n_files,
                           const gchar *hint);

  void g_application_release (GApplication *application);
  void g_application_quit (GApplication *application);

  /* GSubProcess */
  typedef struct {} GSubprocess;

  typedef enum {
    G_SUBPROCESS_FLAGS_NONE                  = 0,
    G_SUBPROCESS_FLAGS_STDIN_PIPE            = (1 << 0),
    G_SUBPROCESS_FLAGS_STDIN_INHERIT         = (1 << 1),
    G_SUBPROCESS_FLAGS_STDOUT_PIPE           = (1 << 2),
    G_SUBPROCESS_FLAGS_STDOUT_SILENCE        = (1 << 3),
    G_SUBPROCESS_FLAGS_STDERR_PIPE           = (1 << 4),
    G_SUBPROCESS_FLAGS_STDERR_SILENCE        = (1 << 5),
    G_SUBPROCESS_FLAGS_STDERR_MERGE          = (1 << 6),
    G_SUBPROCESS_FLAGS_INHERIT_FDS           = (1 << 7)
  } GSubprocessFlags;

  GSubprocess * g_subprocess_newv (const gchar * const *argv,
                                   GSubprocessFlags flags,
                                   GError **error);

  gboolean g_subprocess_wait (GSubprocess *subprocess,
                              GCancellable *cancellable,
                              GError **error);

  gboolean g_subprocess_wait_check (GSubprocess *subprocess,
                                    GCancellable *cancellable,
                                    GError **error);

  void g_subprocess_wait_async (GSubprocess *subprocess,
                                GCancellable *cancellable,
                                GAsyncReadyCallback callback,
                                gpointer user_data);

  gboolean g_subprocess_wait_finish (GSubprocess *subprocess,
                                     GAsyncResult *result,
                                     GError **error);

  gboolean g_subprocess_get_successful (GSubprocess *subprocess);
  gint g_subprocess_get_exit_status (GSubprocess *subprocess);
  void g_subprocess_send_signal (GSubprocess *subprocess, gint signal_num);
  void g_subprocess_force_exit (GSubprocess *subprocess);
  gboolean g_subprocess_get_if_signaled (GSubprocess *subprocess);
  gboolean g_subprocess_get_if_exited (GSubprocess *subprocess);
  gint g_subprocess_get_term_sig (GSubprocess *subprocess);
  const gchar * g_subprocess_get_identifier (GSubprocess *subprocess);

  GOutputStream * g_subprocess_get_stdin_pipe (GSubprocess *subprocess);
  GInputStream * g_subprocess_get_stdout_pipe (GSubprocess *subprocess);
  GInputStream * g_subprocess_get_stderr_pipe (GSubprocess *subprocess);

  gboolean g_subprocess_communicate (GSubprocess *subprocess,
                                     GBytes *stdin_buf,
                                     GCancellable *cancellable,
                                     GBytes **stdout_buf,
                                     GBytes **stderr_buf,
                                     GError **error);

  gboolean g_subprocess_communicate_utf8 (GSubprocess *subprocess,
                                          GBytes *stdin_buf,
                                          GCancellable *cancellable,
                                          GBytes **stdout_buf,
                                          GBytes **stderr_buf,
                                          GError **error);

  void g_subprocess_communicate_async (GSubprocess *subprocess,
                                       GBytes *stdin_buf,
                                       GCancellable *cancellable,
                                       GAsyncReadyCallback callback,
                                       gpointer user_data);

  void g_subprocess_communicate_async_utf8 (GSubprocess *subprocess,
                                            GBytes *stdin_buf,
                                            GCancellable *cancellable,
                                            GAsyncReadyCallback callback,
                                            gpointer user_data);

  gboolean g_subprocess_communicate_finish (GSubprocess *subprocess,
                                            GAsyncResult *result,
                                            GBytes **stdout_buf,
                                            GBytes **stderr_buf,
                                            GError **error);

  gboolean g_subprocess_communicate_utf8_finish (GSubprocess *subprocess,
                                                 GAsyncResult *result,
                                                 GBytes **stdout_buf,
                                                 GBytes **stderr_buf,
                                                 GError **error);

  /* GCancellable.
     Note the 'typedef void GCancellable' at the top of this file: it cannot be
     redefined as a struct without breaking every cdef above, which also means it
     can never be core.define'd (no ffi.metatype on void). See
     ljglibs/gio/cancellable.moon. */
  GCancellable * g_cancellable_new (void);
  void     g_cancellable_cancel (GCancellable *cancellable);
  gboolean g_cancellable_is_cancelled (GCancellable *cancellable);
  void     g_cancellable_reset (GCancellable *cancellable);

  /* GSocketConnectable / GNetworkAddress */
  typedef struct {} GSocketConnectable;
  typedef struct {} GNetworkAddress;
  typedef struct {} GSocketAddress;

  GSocketConnectable * g_network_address_new (const gchar *hostname, guint16 port);
  GSocketConnectable * g_network_address_new_loopback (guint16 port);
  GSocketConnectable * g_network_address_parse_uri (const gchar *uri,
                                                    guint16 default_port,
                                                    GError **error);
  const gchar * g_network_address_get_hostname (GNetworkAddress *addr);
  guint16       g_network_address_get_port (GNetworkAddress *addr);
  const gchar * g_network_address_get_scheme (GNetworkAddress *addr);

  /* GIOStream */
  typedef struct {} GIOStream;
  GInputStream  * g_io_stream_get_input_stream  (GIOStream *stream);
  GOutputStream * g_io_stream_get_output_stream (GIOStream *stream);
  gboolean g_io_stream_is_closed (GIOStream *stream);
  gboolean g_io_stream_close (GIOStream *stream,
                              GCancellable *cancellable,
                              GError **error);
  void     g_io_stream_close_async (GIOStream *stream,
                                    int io_priority,
                                    GCancellable *cancellable,
                                    GAsyncReadyCallback callback,
                                    gpointer user_data);
  gboolean g_io_stream_close_finish (GIOStream *stream,
                                     GAsyncResult *result,
                                     GError **error);

  /* GSocketConnection */
  typedef struct {} GSocketConnection;
  gboolean g_socket_connection_is_connected (GSocketConnection *connection);
  GSocketAddress * g_socket_connection_get_remote_address (GSocketConnection *connection,
                                                           GError **error);

  /* TLS */
  typedef enum {
    G_TLS_CERTIFICATE_NO_FLAGS      = 0,
    G_TLS_CERTIFICATE_UNKNOWN_CA    = 1 << 0,
    G_TLS_CERTIFICATE_BAD_IDENTITY  = 1 << 1,
    G_TLS_CERTIFICATE_NOT_ACTIVATED = 1 << 2,
    G_TLS_CERTIFICATE_EXPIRED       = 1 << 3,
    G_TLS_CERTIFICATE_REVOKED       = 1 << 4,
    G_TLS_CERTIFICATE_INSECURE      = 1 << 5,
    G_TLS_CERTIFICATE_GENERIC_ERROR = 1 << 6,
    G_TLS_CERTIFICATE_VALIDATE_ALL  = 0x007f
  } GTlsCertificateFlags;

  typedef struct {} GTlsBackend;
  GTlsBackend * g_tls_backend_get_default (void);
  gboolean      g_tls_backend_supports_tls (GTlsBackend *backend);

  /* Error domains. A GError code only means something paired with its domain -
     G_IO_ERROR_CANCELLED and a TLS error can share a number. */
  GQuark g_io_error_quark (void);
  GQuark g_tls_error_quark (void);
  GQuark g_resolver_error_quark (void);

  typedef enum {
    G_IO_ERROR_FAILED = 0,
    G_IO_ERROR_NOT_FOUND = 1,
    G_IO_ERROR_CANCELLED = 19,
    G_IO_ERROR_TIMED_OUT = 24,
    G_IO_ERROR_HOST_NOT_FOUND = 34,
    G_IO_ERROR_CONNECTION_REFUSED = 39,
    G_IO_ERROR_HOST_UNREACHABLE = 41,
    G_IO_ERROR_NETWORK_UNREACHABLE = 42,
    G_IO_ERROR_CONNECTION_CLOSED = 44
  } GIOErrorEnum;

  /* GSocketClient.
     Deliberately no g_socket_client_set_tls_validation_flags: the default is
     already VALIDATE_ALL and the setter is deprecated precisely because it was
     used to turn validation off. */
  typedef struct {} GSocketClient;

  GSocketClient * g_socket_client_new (void);
  void     g_socket_client_set_tls (GSocketClient *client, gboolean tls);
  gboolean g_socket_client_get_tls (GSocketClient *client);
  void     g_socket_client_set_timeout (GSocketClient *client, guint timeout);
  guint    g_socket_client_get_timeout (GSocketClient *client);
  void     g_socket_client_set_enable_proxy (GSocketClient *client, gboolean enable);
  gboolean g_socket_client_get_enable_proxy (GSocketClient *client);

  void g_socket_client_connect_async (GSocketClient *client,
                                      GSocketConnectable *connectable,
                                      GCancellable *cancellable,
                                      GAsyncReadyCallback callback,
                                      gpointer user_data);
  GSocketConnection * g_socket_client_connect_finish (GSocketClient *client,
                                                      GAsyncResult *result,
                                                      GError **error);
  void g_socket_client_connect_to_uri_async (GSocketClient *client,
                                             const gchar *uri,
                                             guint16 default_port,
                                             GCancellable *cancellable,
                                             GAsyncReadyCallback callback,
                                             gpointer user_data);
  GSocketConnection * g_socket_client_connect_to_uri_finish (GSocketClient *client,
                                                             GAsyncResult *result,
                                                             GError **error);

  /* GProxyResolver - consulted automatically by GSocketClient */
  typedef struct {} GProxyResolver;
  GProxyResolver * g_proxy_resolver_get_default (void);
  gboolean         g_proxy_resolver_is_supported (GProxyResolver *resolver);

  /* Server side - used by the spec test server, not by the client */
  typedef struct {} GSocketListener;
  typedef struct {} GSocketService;

  GSocketService * g_socket_service_new (void);
  void     g_socket_service_start (GSocketService *service);
  void     g_socket_service_stop (GSocketService *service);
  gboolean g_socket_service_is_active (GSocketService *service);
  guint16  g_socket_listener_add_any_inet_port (GSocketListener *listener,
                                                GObject *source_object,
                                                GError **error);
  void     g_socket_listener_close (GSocketListener *listener);
]]
