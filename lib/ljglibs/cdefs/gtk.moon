-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'
require 'ljglibs.cdefs.glib'

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

    /* GtkWidget */
  typedef struct {} GtkWidget;

  void gtk_widget_override_background_color (GtkWidget *widget,
                                             GtkStateFlags state,
                                             const GdkRGBA *color);
]]
