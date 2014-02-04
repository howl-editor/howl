-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
require 'ljglibs.cdefs.glib'
require 'ljglibs.cdefs.gio'

ffi.cdef [[
  /* standard enums */
  typedef enum
  {
    GTK_STATE_FLAG_NORMAL       = 0,
    GTK_STATE_FLAG_ACTIVE       = 1 << 0,
    GTK_STATE_FLAG_PRELIGHT     = 1 << 1,
    GTK_STATE_FLAG_SELECTED     = 1 << 2,
    GTK_STATE_FLAG_INSENSITIVE  = 1 << 3,
    GTK_STATE_FLAG_INCONSISTENT = 1 << 4,
    GTK_STATE_FLAG_FOCUSED      = 1 << 5
  } GtkStateFlags;

  typedef enum {
    GTK_POS_LEFT,
    GTK_POS_RIGHT,
    GTK_POS_TOP,
    GTK_POS_BOTTOM
  } GtkPositionType;

  typedef enum {
    GTK_ORIENTATION_HORIZONTAL,
    GTK_ORIENTATION_VERTICAL
  } GtkOrientation;

  typedef enum {
    GTK_PACK_START,
    GTK_PACK_END
  } GtkPackType;

  /* GtkCssProvider */
  typedef struct {} GtkStyleProvider;
  typedef struct {} GtkCssProvider;

  GtkCssProvider * gtk_css_provider_new (void);

  gboolean gtk_css_provider_load_from_data (GtkCssProvider *css_provider,
                                            const gchar *data,
                                            gssize length,
                                            GError **error);

  /* GtkStyleContext */
  typedef struct {} GtkStyleContext;

  GtkStyleContext * gtk_style_context_new (void);
  void gtk_style_context_add_class (GtkStyleContext *context,
                                    const gchar *class_name);

  void gtk_style_context_add_provider_for_screen (GdkScreen *screen,
                                                  GtkStyleProvider *provider,
                                                  guint priority);

  /* GtkWidget */
  typedef struct {} GtkWidget;

  const gchar * gtk_widget_get_name (GtkWidget *widget);
  void gtk_widget_realize (GtkWidget *widget);
  void gtk_widget_show (GtkWidget *widget);
  void gtk_widget_show_all (GtkWidget *widget);
  void gtk_widget_hide (GtkWidget *widget);
  GtkStyleContext * gtk_widget_get_style_context (GtkWidget *widget);
  void gtk_widget_override_background_color (GtkWidget *widget,
                                             GtkStateFlags state,
                                             const GdkRGBA *color);
  GdkWindow * gtk_widget_get_window (GtkWidget *widget);
  void gtk_widget_grab_focus (GtkWidget *widget);
  void gtk_widget_destroy (GtkWidget *widget);
  int gtk_widget_get_allocated_width (GtkWidget *widget);
  int gtk_widget_get_allocated_height (GtkWidget *widget);

  /* GtkBin */
  typedef struct {} GtkBin;
  GtkWidget * gtk_bin_get_child (GtkBin *bin);

  /* GtkGrid */
  typedef struct {} GtkGrid;

   /* GtkContainer */
  typedef struct {} GtkContainer;

  void gtk_container_add (GtkContainer *container, GtkWidget *widget);
  void gtk_container_remove (GtkContainer *container, GtkWidget *widget);

  void gtk_container_child_get (GtkContainer *container,
                                GtkWidget *child,
                                const gchar *first_prop_name,
                                ...);

  void gtk_container_child_set (GtkContainer *container,
                                GtkWidget *child,
                                const gchar *first_prop_name,
                                ...);

  /* GtkAlignment */
  typedef struct {} GtkAlignment;

  GtkAlignment * gtk_alignment_new (gfloat xalign,
                                    gfloat yalign,
                                    gfloat xscale,
                                    gfloat yscale);

  void gtk_alignment_set (GtkAlignment *alignment,
                          gfloat xalign,
                          gfloat yalign,
                          gfloat xscale,
                          gfloat yscale);

  void gtk_alignment_get_padding (GtkAlignment *alignment,
                                  guint *padding_top,
                                  guint *padding_bottom,
                                  guint *padding_left,
                                  guint *padding_right);

  void gtk_alignment_set_padding (GtkAlignment *alignment,
                                  guint padding_top,
                                  guint padding_bottom,
                                  guint padding_left,
                                  guint padding_right);

  /* GtkBox */
  typedef struct {} GtkBox;
  GtkBox * gtk_box_new (GtkOrientation orientation, gint spacing);
  void gtk_box_pack_start (GtkBox *box,
                           GtkWidget *child,
                           gboolean expand,
                           gboolean fill,
                           guint padding);

  void gtk_box_pack_end (GtkBox *box,
                         GtkWidget *child,
                         gboolean expand,
                         gboolean fill,
                         guint padding);

  /* GtkEventBox */
  typedef struct {} GtkEventBox;
  GtkEventBox * gtk_event_box_new (void);

  /* GtkWindow */
  typedef enum {
    GTK_WINDOW_TOPLEVEL,
    GTK_WINDOW_POPUP
  } GtkWindowType;

  typedef struct {} GtkWindow;

  GtkWindow * gtk_window_new (void);

  const gchar * gtk_window_get_title (GtkWindow *window);
  void gtk_window_set_title (GtkWindow *window, const gchar *title);
  GtkWindowType gtk_window_get_window_type (GtkWindow *window);

  void gtk_window_set_default_size (GtkWindow *window,
                                    gint width,
                                    gint height);

  void gtk_window_get_size (GtkWindow *window, gint *width, gint *height);
  void gtk_window_resize (GtkWindow *window, gint width, gint height);
  GtkWidget * gtk_window_get_focus (GtkWindow *window);
  void gtk_window_set_focus (GtkWindow *window, GtkWidget *focus);

  gboolean gtk_window_set_default_icon_from_file (const gchar *filename,
                                                  GError **err);
  void gtk_window_fullscreen (GtkWindow *window);
  void gtk_window_unfullscreen (GtkWindow *window);
  void gtk_window_maximize (GtkWindow *window);
  void gtk_window_unmaximize (GtkWindow *window);

  /* GtkOffscreenWindow */
  typedef struct {} GtkOffscreenWindow;
  GtkOffscreenWindow * gtk_offscreen_window_new (void);

  /* GtkApplication */
  typedef struct {} GtkApplication;
  GtkApplication * gtk_application_new (const gchar *application_id,
                                        GApplicationFlags flags);
  void gtk_application_add_window (GtkApplication *application, GtkWindow *window);
  void gtk_application_remove_window (GtkApplication *application, GtkWindow *window);

]]
