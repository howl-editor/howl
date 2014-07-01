-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

require 'ljglibs.cdefs.glib'
require 'ljglibs.cdefs.cairo'
ffi = require 'ffi'

ffi.cdef [[
  /* events */
  typedef enum {
    GDK_NOTHING           = -1,
    GDK_DELETE            = 0,
    GDK_DESTROY           = 1,
    GDK_EXPOSE            = 2,
    GDK_MOTION_NOTIFY     = 3,
    GDK_BUTTON_PRESS      = 4,
    GDK_2BUTTON_PRESS     = 5,
    GDK_DOUBLE_BUTTON_PRESS = GDK_2BUTTON_PRESS,
    GDK_3BUTTON_PRESS     = 6,
    GDK_TRIPLE_BUTTON_PRESS = GDK_3BUTTON_PRESS,
    GDK_BUTTON_RELEASE    = 7,
    GDK_KEY_PRESS         = 8,
    GDK_KEY_RELEASE       = 9,
    GDK_ENTER_NOTIFY      = 10,
    GDK_LEAVE_NOTIFY      = 11,
    GDK_FOCUS_CHANGE      = 12,
    GDK_CONFIGURE         = 13,
    GDK_MAP               = 14,
    GDK_UNMAP             = 15,
    GDK_PROPERTY_NOTIFY   = 16,
    GDK_SELECTION_CLEAR   = 17,
    GDK_SELECTION_REQUEST = 18,
    GDK_SELECTION_NOTIFY  = 19,
    GDK_PROXIMITY_IN      = 20,
    GDK_PROXIMITY_OUT     = 21,
    GDK_DRAG_ENTER        = 22,
    GDK_DRAG_LEAVE        = 23,
    GDK_DRAG_MOTION       = 24,
    GDK_DRAG_STATUS       = 25,
    GDK_DROP_START        = 26,
    GDK_DROP_FINISHED     = 27,
    GDK_CLIENT_EVENT      = 28,
    GDK_VISIBILITY_NOTIFY = 29,
    GDK_SCROLL            = 31,
    GDK_WINDOW_STATE      = 32,
    GDK_SETTING           = 33,
    GDK_OWNER_CHANGE      = 34,
    GDK_GRAB_BROKEN       = 35,
    GDK_DAMAGE            = 36,
    GDK_TOUCH_BEGIN       = 37,
    GDK_TOUCH_UPDATE      = 38,
    GDK_TOUCH_END         = 39,
    GDK_TOUCH_CANCEL      = 40,
    GDK_EVENT_LAST        /* helper variable for decls */
  } GdkEventType;

  typedef enum
  {
    GDK_EXPOSURE_MASK             = 1 << 1,
    GDK_POINTER_MOTION_MASK       = 1 << 2,
    GDK_POINTER_MOTION_HINT_MASK  = 1 << 3,
    GDK_BUTTON_MOTION_MASK        = 1 << 4,
    GDK_BUTTON1_MOTION_MASK       = 1 << 5,
    GDK_BUTTON2_MOTION_MASK       = 1 << 6,
    GDK_BUTTON3_MOTION_MASK       = 1 << 7,
    GDK_BUTTON_PRESS_MASK         = 1 << 8,
    GDK_BUTTON_RELEASE_MASK       = 1 << 9,
    GDK_KEY_PRESS_MASK            = 1 << 10,
    GDK_KEY_RELEASE_MASK          = 1 << 11,
    GDK_ENTER_NOTIFY_MASK         = 1 << 12,
    GDK_LEAVE_NOTIFY_MASK         = 1 << 13,
    GDK_FOCUS_CHANGE_MASK         = 1 << 14,
    GDK_STRUCTURE_MASK            = 1 << 15,
    GDK_PROPERTY_CHANGE_MASK      = 1 << 16,
    GDK_VISIBILITY_NOTIFY_MASK    = 1 << 17,
    GDK_PROXIMITY_IN_MASK         = 1 << 18,
    GDK_PROXIMITY_OUT_MASK        = 1 << 19,
    GDK_SUBSTRUCTURE_MASK         = 1 << 20,
    GDK_SCROLL_MASK               = 1 << 21,
    GDK_TOUCH_MASK                = 1 << 22,
    GDK_SMOOTH_SCROLL_MASK        = 1 << 23,
    GDK_ALL_EVENTS_MASK           = 0xFFFFFE
  } GdkEventMask;


  typedef struct {
    GdkEventType type;
    gpointer window;
    gint8 send_event;
    guint32 time;
    guint state;
    guint keyval;
    gint length;
    gchar *string;
    guint16 hardware_keycode;
    guint8 group;
    guint is_modifier : 1;
  } GdkEventKey;

  gchar * gdk_keyval_name(guint keyval);
  guint32 gdk_keyval_to_unicode(guint keyval);

  typedef cairo_rectangle_int_t         GdkRectangle;

  /* screen */
  typedef struct {} GdkScreen;
  GdkScreen * gdk_screen_get_default (void);
  gint gdk_screen_get_number (GdkScreen *screen);
  gint gdk_screen_get_width (GdkScreen *screen);
  gint gdk_screen_get_height (GdkScreen *screen);
  gint gdk_screen_get_width_mm (GdkScreen *screen);
  gint gdk_screen_get_height_mm (GdkScreen *screen);

  /* GdkRGBA */
  typedef struct {
    gdouble red;
    gdouble green;
    gdouble blue;
    gdouble alpha;
  } GdkRGBA;

  gboolean gdk_rgba_parse (GdkRGBA *rgba, const gchar *spec);

  /* GdkWindow */
  typedef struct {} GdkWindow;

  typedef enum {
    GDK_WINDOW_STATE_WITHDRAWN  = 1 << 0,
    GDK_WINDOW_STATE_ICONIFIED  = 1 << 1,
    GDK_WINDOW_STATE_MAXIMIZED  = 1 << 2,
    GDK_WINDOW_STATE_STICKY     = 1 << 3,
    GDK_WINDOW_STATE_FULLSCREEN = 1 << 4,
    GDK_WINDOW_STATE_ABOVE      = 1 << 5,
    GDK_WINDOW_STATE_BELOW      = 1 << 6,
    GDK_WINDOW_STATE_FOCUSED    = 1 << 7,
    GDK_WINDOW_STATE_TILED      = 1 << 8
  } GdkWindowState;

  GdkWindowState gdk_window_get_state (GdkWindow *window);
  void gdk_window_get_position (GdkWindow *window,
                                gint *x,
                                gint *y);

  GdkEventMask gdk_window_get_events (GdkWindow *window);
  void gdk_window_set_events (GdkWindow *window, GdkEventMask event_mask);
  /* GdkAtom

  This is really an opaque struct, but we're going to have to break the
  abstraction here, as it's ret-by-value */
  typedef struct { gulong val; } GdkAtom;
  GdkAtom gdk_atom_intern (const gchar *atom_name, gboolean only_if_exists);
  gchar * gdk_atom_name (GdkAtom atom);
]]
