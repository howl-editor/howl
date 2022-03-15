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

  /* Forward declarations, more definintions below */
  typedef struct {} GtkIMContext;


  /* GtkCssProvider */
  typedef struct {} GtkStyleProvider;
  typedef struct {} GtkCssProvider;

  GtkCssProvider * gtk_css_provider_new (void);

  void gtk_css_provider_load_from_data (
    GtkCssProvider* css_provider,
    const char* data,
    gssize length
  );

  void gtk_css_provider_load_from_path (
    GtkCssProvider* css_provider,
    const char* path
  );

  char * gtk_css_provider_to_string (GtkCssProvider *provider);

  typedef struct {
    gsize bytes;
    gsize chars;
    gsize lines;
    gsize line_bytes;
    gsize line_chars;
  } GtkCssLocation;

  /* GtkCssSection */
  typedef struct {} GtkCssSection;
  char* gtk_css_section_to_string(const GtkCssSection* section);
  const GtkCssLocation* gtk_css_section_get_start_location (const GtkCssSection* section);
  const GtkCssLocation* gtk_css_section_get_end_location (const GtkCssSection* section);

  /* GtkStyleContext */
  typedef struct {} GtkStyleContext;

  GtkStyleContext * gtk_style_context_new (void);
  void gtk_style_context_add_class (GtkStyleContext *context,
                                    const gchar *class_name);
  void gtk_style_context_remove_class (GtkStyleContext *context, const gchar *class_name);
  void gtk_style_context_get_background_color (GtkStyleContext *context,
                                               GtkStateFlags state,
                                               GdkRGBA *color);
  void gtk_style_context_add_provider (
    GtkStyleContext* context,
    GtkStyleProvider* provider,
    guint priority
  );

  void gtk_style_context_add_provider_for_display (GdkDisplay *display,
                                                  GtkStyleProvider *provider,
                                                  guint priority);

  char* gtk_style_context_to_string (
    GtkStyleContext* context,
    /* GtkStyleContextPrintFlags flags */
    int flags
  );

  /* Controllers */
  typedef struct {} GtkEventController;

    /* Key controller */
  typedef struct {} GtkEventControllerKey;
  GtkEventControllerKey * gtk_event_controller_key_new(void);
  void gtk_event_controller_key_set_im_context(
    GtkEventControllerKey* controller,
    GtkIMContext* im_context
  );

    /* Focus controller */
  typedef struct {} GtkEventControllerFocus;
  GtkEventControllerFocus * gtk_event_controller_focus_new(void);

    /* Gesture controller */
  typedef struct {} GtkGesture;
  typedef struct {} GtkGestureSingle;
  typedef struct {} GtkGestureClick;
  GtkGestureClick* gtk_gesture_click_new(void);

  /* Motion controller */
  typedef struct {} GtkEventControllerMotion;
  GtkEventControllerMotion *gtk_event_controller_motion_new (void);

  /* GtkWidget */
  typedef struct {} GtkWidget;

  gboolean gtk_widget_in_destruction (GtkWidget *widget);
  const gchar * gtk_widget_get_name (GtkWidget *widget);
  void gtk_widget_realize (GtkWidget *widget);
  void gtk_widget_show (GtkWidget *widget);
  void gtk_widget_hide (GtkWidget *widget);
  GtkStyleContext * gtk_widget_get_style_context (GtkWidget *widget);
  GdkDisplay* gtk_widget_get_display (GtkWidget* widget);
  void gtk_widget_grab_focus (GtkWidget *widget);
  int gtk_widget_get_allocated_width (GtkWidget *widget);
  int gtk_widget_get_allocated_height (GtkWidget *widget);
  void gtk_widget_set_size_request (GtkWidget *widget,
                                    gint width,
                                    gint height);
  gboolean gtk_widget_translate_coordinates (GtkWidget *src_widget,
                                             GtkWidget *dest_widget,
                                             gint src_x,
                                             gint src_y,
                                             gint *dest_x,
                                             gint *dest_y);

  PangoContext * gtk_widget_create_pango_context (GtkWidget *widget);
  PangoContext * gtk_widget_get_pango_context (GtkWidget *widget);
  void gtk_widget_add_controller (GtkWidget* widget,
                                  GtkEventController* controller);

  void gtk_widget_queue_allocate (GtkWidget *widget);
  void gtk_widget_queue_draw (GtkWidget *widget);
  void gtk_widget_queue_resize (GtkWidget *widget);
  void gtk_widget_queue_draw_area (GtkWidget *widget,
                                   gint x,
                                   gint y,
                                   gint width,
                                   gint height);
  GtkWidget * gtk_widget_get_first_child      (GtkWidget *widget);
  GtkWidget * gtk_widget_get_last_child       (GtkWidget *widget);
  GtkWidget * gtk_widget_get_next_sibling     (GtkWidget *widget);
  GtkWidget * gtk_widget_get_prev_sibling     (GtkWidget *widget);
  void gtk_widget_set_css_classes (GtkWidget* widget, const char** classes);
  char** gtk_widget_get_css_classes(GtkWidget* widget);



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
  void gtk_grid_query_child (GtkGrid* grid,
                             GtkWidget* child,
                             int* column,
                             int* row,
                             int* width,
                             int* height
                            );


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
  void gtk_box_append (GtkBox *box, GtkWidget *child);
  void gtk_box_prepend (GtkBox *box, GtkWidget *child);

  /* GtkWindow */
  typedef struct {} GtkWindow;

  GtkWindow * gtk_window_new ();
  void gtk_window_destroy (GtkWindow* window);

  const gchar * gtk_window_get_title (GtkWindow *window);
  void gtk_window_set_title (GtkWindow *window, const gchar *title);

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

  /*** Clipboard & selections ***/

  /* GtkTargetEntry */
  typedef struct {} GtkTargetEntry;

  typedef enum {
    GTK_TARGET_SAME_APP = 1 << 0,
    GTK_TARGET_SAME_WIDGET = 1 << 1,
    GTK_TARGET_OTHER_APP = 1 << 2,
    GTK_TARGET_OTHER_WIDGET = 1 << 3
  } GtkTargetFlags;

  GtkTargetEntry * gtk_target_entry_new (const gchar *target,
                                         guint flags,
                                         guint info);

  void gtk_target_entry_free (GtkTargetEntry *data);

  /* GtkTargetList */
  typedef struct {} GtkTargetList;

  GtkTargetList * gtk_target_list_new (const GtkTargetEntry *targets,
                                      guint ntargets);
  void gtk_target_list_unref (GtkTargetList *list);
  void gtk_target_list_add (GtkTargetList *list,
                            GdkAtom target,
                            guint flags,
                            guint info);

  /* GtkTargetTable */
  GtkTargetEntry * gtk_target_table_new_from_list (GtkTargetList *list,
                                                   gint *n_targets);
  void gtk_target_table_free (GtkTargetEntry *targets,
                              gint n_targets);

  /* GtkSelectionData */
  typedef struct {} GtkSelectionData;

  gboolean gtk_selection_data_set_text (GtkSelectionData *selection_data,
                                        const gchar *str,
                                        gint len);

  /* GtkSpinner */
  typedef struct {} GtkSpinner;
  GtkSpinner * gtk_spinner_new (void);
  void gtk_spinner_start (GtkSpinner *spinner);
  void gtk_spinner_stop (GtkSpinner *spinner);

  /* GtkDrawingArea */
  typedef struct {} GtkDrawingArea;

  typedef void (*GAsyncReadyCallback) (GObject *source_object,
                                       GAsyncResult *res,
                                       gpointer user_data);

  typedef void (*GtkDrawingAreaDrawFunc) (
    GtkDrawingArea* drawing_area,
    cairo_t* cr,
    int width,
    int height,
    gpointer user_data
  );

  GtkDrawingArea * gtk_drawing_area_new (void);
  void gtk_drawing_area_set_draw_func (
    GtkDrawingArea* self,
    GtkDrawingAreaDrawFunc draw_func,
    gpointer user_data,
    GDestroyNotify destroy
  );


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
  void     gtk_im_context_set_client_widget   (GtkIMContext       *context,
                           GtkWidget          *widget);
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

  const gchar * gtk_check_version (guint required_major,
                                   guint required_minor,
                                   guint required_micro);
]]
