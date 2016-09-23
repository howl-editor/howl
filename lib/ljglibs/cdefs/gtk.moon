-- Copyright 2013-2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
require 'ljglibs.cdefs.glib'
require 'ljglibs.cdefs.gio'
require 'ljglibs.cdefs.pango'

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

  typedef enum {
    GTK_JUSTIFY_LEFT,
    GTK_JUSTIFY_RIGHT,
    GTK_JUSTIFY_CENTER,
    GTK_JUSTIFY_FILL
  } GtkJustification;

  typedef enum {
    GTK_WIN_POS_NONE,
    GTK_WIN_POS_CENTER,
    GTK_WIN_POS_MOUSE,
    GTK_WIN_POS_CENTER_ALWAYS,
    GTK_WIN_POS_CENTER_ON_PARENT
  } GtkWindowPosition;

  typedef enum {
    GTK_ALIGN_FILL,
    GTK_ALIGN_START,
    GTK_ALIGN_END,
    GTK_ALIGN_CENTER,
    GTK_ALIGN_BASELINE,
  } GtkAlign;

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
  void gtk_style_context_remove_class (GtkStyleContext *context, const gchar *class_name);
  void gtk_style_context_get_background_color (GtkStyleContext *context,
                                               GtkStateFlags state,
                                               GdkRGBA *color);
  void gtk_style_context_add_provider_for_screen (GdkScreen *screen,
                                                  GtkStyleProvider *provider,
                                                  guint priority);

  /* GtkWidget */
  typedef struct {} GtkWidget;

  gboolean gtk_widget_in_destruction (GtkWidget *widget);
  const gchar * gtk_widget_get_name (GtkWidget *widget);
  void gtk_widget_realize (GtkWidget *widget);
  void gtk_widget_show (GtkWidget *widget);
  void gtk_widget_show_all (GtkWidget *widget);
  void gtk_widget_hide (GtkWidget *widget);
  GtkStyleContext * gtk_widget_get_style_context (GtkWidget *widget);
  void gtk_widget_override_background_color (GtkWidget *widget,
                                             GtkStateFlags state,
                                             const GdkRGBA *color);
  void gtk_widget_override_font (GtkWidget *widget,
                          const PangoFontDescription *font_desc);
  GdkWindow * gtk_widget_get_window (GtkWidget *widget);
  GdkScreen * gtk_widget_get_screen (GtkWidget *widget);
  void gtk_widget_grab_focus (GtkWidget *widget);
  void gtk_widget_destroy (GtkWidget *widget);
  int gtk_widget_get_allocated_width (GtkWidget *widget);
  int gtk_widget_get_allocated_height (GtkWidget *widget);
  void gtk_widget_set_size_request (GtkWidget *widget,
                                    gint width,
                                    gint height);
  GtkWidget * gtk_widget_get_toplevel (GtkWidget *widget);
  gboolean gtk_widget_translate_coordinates (GtkWidget *src_widget,
                                             GtkWidget *dest_widget,
                                             gint src_x,
                                             gint src_y,
                                             gint *dest_x,
                                             gint *dest_y);

  PangoContext * gtk_widget_create_pango_context (GtkWidget *widget);
  PangoContext * gtk_widget_get_pango_context (GtkWidget *widget);
  void gtk_widget_add_events (GtkWidget *widget, gint events);

  void gtk_widget_queue_draw (GtkWidget *widget);
  void gtk_widget_queue_draw_area (GtkWidget *widget,
                                   gint x,
                                   gint y,
                                   gint width,
                                   gint height);

  GdkVisual * gtk_widget_get_visual(GtkWidget *widget);
  void gtk_widget_set_visual(GtkWidget *widget, GdkVisual *visual);

  /* GtkBin */
  typedef struct {} GtkBin;
  GtkWidget * gtk_bin_get_child (GtkBin *bin);

  /* GtkGrid */
  typedef struct {} GtkGrid;

  GtkGrid * gtk_grid_new (void);
  void gtk_grid_attach (GtkGrid *grid,
                        GtkWidget *child,
                        gint left,
                        gint top,
                        gint width,
                        gint height);

  void gtk_grid_attach_next_to (GtkGrid *grid,
                                GtkWidget *child,
                                GtkWidget *sibling,
                                GtkPositionType side,
                                gint width,
                                gint height);
  GtkWidget * gtk_grid_get_child_at (GtkGrid *grid, gint left, gint top);
  void gtk_grid_insert_row (GtkGrid *grid, gint position);
  void gtk_grid_insert_column (GtkGrid *grid, gint position);
  void gtk_grid_remove_row (GtkGrid *grid, gint position);
  void gtk_grid_remove_column (GtkGrid *grid, gint position);
  void gtk_grid_insert_next_to (GtkGrid *grid,
                                GtkWidget *sibling,
                                GtkPositionType side);

   /* GtkContainer */
  typedef struct {} GtkContainer;

  void gtk_container_add (GtkContainer *container, GtkWidget *widget);
  void gtk_container_remove (GtkContainer *container, GtkWidget *widget);
  GtkWidget * gtk_container_get_focus_child (GtkContainer *container);
  void gtk_container_set_focus_child (GtkContainer *container, GtkWidget *child);
  GList * gtk_container_get_children (GtkContainer *container);
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

  GtkWindow * gtk_window_new  (GtkWindowType type);

  const gchar * gtk_window_get_title (GtkWindow *window);
  void gtk_window_set_title (GtkWindow *window, const gchar *title);
  GtkWindowType gtk_window_get_window_type (GtkWindow *window);

  void gtk_window_set_default_size (GtkWindow *window,
                                    gint width,
                                    gint height);

  void gtk_window_get_size (GtkWindow *window, gint *width, gint *height);
  void gtk_window_resize (GtkWindow *window, gint width, gint height);
  void gtk_window_move (GtkWindow *window, gint x, gint y);
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

  /* GtkMisc */
  typedef struct {} GtkMisc;

  /* GtkLabel */
  typedef struct {} GtkLabel;

  GtkLabel * gtk_label_new (const gchar *str);
  const gchar * gtk_label_get_text (GtkLabel *label);
  void gtk_label_set_text (GtkLabel *label, const gchar *str);

  /* GtkEntry */
  typedef struct {} GtkEntry;
  GtkEntry * gtk_entry_new (void);

  typedef struct {
    gchar *target;
    guint  flags;
    guint  info;
  } GtkTargetEntry;

  /* GtkClipboard */
  typedef struct {} GtkClipboard;
  typedef GVCallback3 GtkClipboardTextReceivedFunc;

  GtkClipboard * gtk_clipboard_get (GdkAtom selection);
  gchar * gtk_clipboard_wait_for_text (GtkClipboard *clipboard);
  void gtk_clipboard_request_text (GtkClipboard *clipboard,
                                   GtkClipboardTextReceivedFunc callback,
                                   gpointer user_data);
  void gtk_clipboard_clear (GtkClipboard *clipboard);
  void gtk_clipboard_set_text (GtkClipboard *clipboard,
                               const gchar *text,
                               gint len);
  void gtk_clipboard_store (GtkClipboard *clipboard);
  void gtk_clipboard_set_can_store (GtkClipboard *clipboard,
                                    const GtkTargetEntry *targets,
                                    gint n_targets);

  /* GtkSpinner */
  typedef struct {} GtkSpinner;
  GtkSpinner * gtk_spinner_new (void);
  void gtk_spinner_start (GtkSpinner *spinner);
  void gtk_spinner_stop (GtkSpinner *spinner);

  /* GtkDrawingArea */
  typedef struct {} GtkDrawingArea;
  GtkDrawingArea * gtk_drawing_area_new (void);

  /* GtkAdjustment */
  typedef struct {} GtkAdjustment;

  GtkAdjustment * gtk_adjustment_new (gdouble value,
                                      gdouble lower,
                                      gdouble upper,
                                      gdouble step_increment,
                                      gdouble page_increment,
                                      gdouble page_size);

  gdouble gtk_adjustment_get_value (GtkAdjustment *adjustment);

  void gtk_adjustment_set_value (GtkAdjustment *adjustment,
                                 gdouble value);

  void gtk_adjustment_clamp_page (GtkAdjustment *adjustment,
                                  gdouble lower,
                                  gdouble upper);

  void gtk_adjustment_changed (GtkAdjustment *adjustment);

  void gtk_adjustment_value_changed (GtkAdjustment *adjustment);

  void gtk_adjustment_configure (GtkAdjustment *adjustment,
                                 gdouble value,
                                 gdouble lower,
                                 gdouble upper,
                                 gdouble step_increment,
                                 gdouble page_increment,
                                 gdouble page_size);

  gdouble gtk_adjustment_get_lower (GtkAdjustment *adjustment);
  gdouble gtk_adjustment_get_page_increment (GtkAdjustment *adjustment);
  gdouble gtk_adjustment_get_page_size (GtkAdjustment *adjustment);
  gdouble gtk_adjustment_get_step_increment (GtkAdjustment *adjustment);
  gdouble gtk_adjustment_get_minimum_increment (GtkAdjustment *adjustment);
  gdouble gtk_adjustment_get_upper (GtkAdjustment *adjustment);
  void gtk_adjustment_set_lower (GtkAdjustment *adjustment,
                                 gdouble lower);
  void gtk_adjustment_set_page_increment (GtkAdjustment *adjustment,
                                          gdouble page_increment);
  void gtk_adjustment_set_page_size (GtkAdjustment *adjustment,
                                     gdouble page_size);
  void gtk_adjustment_set_step_increment (GtkAdjustment *adjustment,
                                          gdouble step_increment);
  void gtk_adjustment_set_upper (GtkAdjustment *adjustment,
                                 gdouble upper);

  /* GtkScrolledWindow */
  typedef struct {} GtkScrolledWindow;
  GtkScrolledWindow * gtk_scrolled_window_new (GtkAdjustment *hadjustment,
                                               GtkAdjustment *vadjustment);

  GtkAdjustment *
  gtk_scrolled_window_get_hadjustment (GtkScrolledWindow *scrolled_window);

  void
  gtk_scrolled_window_set_hadjustment (GtkScrolledWindow *scrolled_window,
                                       GtkAdjustment *hadjustment);

  GtkAdjustment *
  gtk_scrolled_window_get_vadjustment (GtkScrolledWindow *scrolled_window);

  void
  gtk_scrolled_window_set_vadjustment (GtkScrolledWindow *scrolled_window,
                                       GtkAdjustment *vadjustment);

  /* GtkRange */
  typedef struct {} GtkRange;

  /* GtkScrollbar */
  typedef struct {} GtkScrollbar;
  GtkScrollbar * gtk_scrollbar_new (GtkOrientation orientation,
                                    GtkAdjustment *adjustment);
  /* GtkViewport */
  typedef struct {} GtkViewport;
  GtkViewport * gtk_viewport_new (GtkAdjustment *hadjustment,
                                  GtkAdjustment *vadjustment);

  /* GtkSettings */
  typedef struct {} GtkSettings;
  GtkSettings * gtk_settings_get_default (void);
  GtkSettings * gtk_settings_get_for_screen (GdkScreen *screen);

  /* GtkIMContext */
  typedef struct {} GtkIMContext;
  void     gtk_im_context_set_client_window   (GtkIMContext       *context,
                           GdkWindow          *window);
  void     gtk_im_context_get_preedit_string  (GtkIMContext       *context,
                           gchar             **str,
                           PangoAttrList     **attrs,
                           gint               *cursor_pos);
  gboolean gtk_im_context_filter_keypress     (GtkIMContext       *context,
                           GdkEventKey        *event);
  void     gtk_im_context_focus_in            (GtkIMContext       *context);
  void     gtk_im_context_focus_out           (GtkIMContext       *context);
  void     gtk_im_context_reset               (GtkIMContext       *context);
  void     gtk_im_context_set_cursor_location (GtkIMContext       *context,
                           const GdkRectangle *area);
  void     gtk_im_context_set_use_preedit     (GtkIMContext       *context,
                           gboolean            use_preedit);
  void     gtk_im_context_set_surrounding     (GtkIMContext       *context,
                           const gchar        *text,
                           gint                len,
                           gint                cursor_index);
  gboolean gtk_im_context_get_surrounding     (GtkIMContext       *context,
                           gchar             **text,
                           gint               *cursor_index);
  gboolean gtk_im_context_delete_surrounding  (GtkIMContext       *context,
                           gint                offset,
                           gint                n_chars);

  typedef struct {} GtkIMContextSimple;
  GtkIMContextSimple * gtk_im_context_simple_new (void);

  /* Misc */
  gboolean gtk_cairo_should_draw_window (cairo_t *cr,
                                         GdkWindow *window);

  guint gtk_get_major_version (void);
  guint gtk_get_minor_version (void);
  guint gtk_get_micro_version (void);
]]
