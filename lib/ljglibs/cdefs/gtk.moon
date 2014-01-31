-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'
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

  void gtk_style_context_add_provider_for_screen (GdkScreen *screen,
                                                  GtkStyleProvider *provider,
                                                  guint priority);

  /* GtkApplication */
  typedef struct {} GtkApplication;
  GtkApplication * gtk_application_new (const gchar *application_id,
                                        GApplicationFlags flags);

  /* GtkWidget */
  typedef struct {} GtkWidget;

  void gtk_widget_realize (GtkWidget *widget);
  void gtk_widget_show (GtkWidget *widget);
  void gtk_widget_hide (GtkWidget *widget);
  void gtk_widget_override_background_color (GtkWidget *widget,
                                             GtkStateFlags state,
                                             const GdkRGBA *color);

  /* GtkBin */
  typedef struct {} GtkBin;
  GtkWidget * gtk_bin_get_child (GtkBin *bin);

  /* GtkGrid */
  typedef struct {} GtkGrid;

   /* GtkContainer */
  typedef struct {} GtkContainer;

  void gtk_container_add (GtkContainer *container, GtkWidget *widget);
  void gtk_container_remove (GtkContainer *container, GtkWidget *widget);

  /* GtkAlignment */
  typedef struct {} GtkAlignment;

  /* GtkBox */
  typedef struct {} GtkBox;
  GtkBox * gtk_box_new (GtkOrientation orientation, gint spacing);

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
  gboolean gtk_window_set_default_icon_from_file (const gchar *filename,
                                                  GError **err);

  void gtk_application_add_window (GtkApplication *application, GtkWindow *window);
  void gtk_application_remove_window (GtkApplication *application, GtkWindow *window);
]]
