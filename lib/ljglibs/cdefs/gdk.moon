-- Copyright 2013-2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

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

  typedef enum
  {
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

    GDK_MODIFIER_RESERVED_13_MASK  = 1 << 13,
    GDK_MODIFIER_RESERVED_14_MASK  = 1 << 14,
    GDK_MODIFIER_RESERVED_15_MASK  = 1 << 15,
    GDK_MODIFIER_RESERVED_16_MASK  = 1 << 16,
    GDK_MODIFIER_RESERVED_17_MASK  = 1 << 17,
    GDK_MODIFIER_RESERVED_18_MASK  = 1 << 18,
    GDK_MODIFIER_RESERVED_19_MASK  = 1 << 19,
    GDK_MODIFIER_RESERVED_20_MASK  = 1 << 20,
    GDK_MODIFIER_RESERVED_21_MASK  = 1 << 21,
    GDK_MODIFIER_RESERVED_22_MASK  = 1 << 22,
    GDK_MODIFIER_RESERVED_23_MASK  = 1 << 23,
    GDK_MODIFIER_RESERVED_24_MASK  = 1 << 24,
    GDK_MODIFIER_RESERVED_25_MASK  = 1 << 25,

    /* The next few modifiers are used by XKB, so we skip to the end.
     * Bits 15 - 25 are currently unused. Bit 29 is used internally.
     */

    GDK_SUPER_MASK    = 1 << 26,
    GDK_HYPER_MASK    = 1 << 27,
    GDK_META_MASK     = 1 << 28,

    GDK_MODIFIER_RESERVED_29_MASK  = 1 << 29,

    GDK_RELEASE_MASK  = 1 << 30,

    /* Combination of GDK_SHIFT_MASK..GDK_BUTTON5_MASK + GDK_SUPER_MASK
       + GDK_HYPER_MASK + GDK_META_MASK + GDK_RELEASE_MASK */
    GDK_MODIFIER_MASK = 0x5c001fff
  } GdkModifierType;

  typedef enum
  {
    GDK_SCROLL_UP,
    GDK_SCROLL_DOWN,
    GDK_SCROLL_LEFT,
    GDK_SCROLL_RIGHT,
    GDK_SCROLL_SMOOTH
  } GdkScrollDirection;

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

  /* GdkCursor */
  typedef struct {} GdkCursor;

  typedef enum
  {
    GDK_X_CURSOR            = 0,
    GDK_ARROW               = 2,
    GDK_BASED_ARROW_DOWN    = 4,
    GDK_BASED_ARROW_UP      = 6,
    GDK_BOAT                = 8,
    GDK_BOGOSITY            = 10,
    GDK_BOTTOM_LEFT_CORNER  = 12,
    GDK_BOTTOM_RIGHT_CORNER = 14,
    GDK_BOTTOM_SIDE         = 16,
    GDK_BOTTOM_TEE          = 18,
    GDK_BOX_SPIRAL          = 20,
    GDK_CENTER_PTR          = 22,
    GDK_CIRCLE              = 24,
    GDK_CLOCK               = 26,
    GDK_COFFEE_MUG          = 28,
    GDK_CROSS               = 30,
    GDK_CROSS_REVERSE       = 32,
    GDK_CROSSHAIR           = 34,
    GDK_DIAMOND_CROSS       = 36,
    GDK_DOT                 = 38,
    GDK_DOTBOX              = 40,
    GDK_DOUBLE_ARROW        = 42,
    GDK_DRAFT_LARGE         = 44,
    GDK_DRAFT_SMALL         = 46,
    GDK_DRAPED_BOX          = 48,
    GDK_EXCHANGE            = 50,
    GDK_FLEUR               = 52,
    GDK_GOBBLER             = 54,
    GDK_GUMBY               = 56,
    GDK_HAND1               = 58,
    GDK_HAND2               = 60,
    GDK_HEART               = 62,
    GDK_ICON                = 64,
    GDK_IRON_CROSS          = 66,
    GDK_LEFT_PTR            = 68,
    GDK_LEFT_SIDE           = 70,
    GDK_LEFT_TEE            = 72,
    GDK_LEFTBUTTON          = 74,
    GDK_LL_ANGLE            = 76,
    GDK_LR_ANGLE            = 78,
    GDK_MAN                 = 80,
    GDK_MIDDLEBUTTON        = 82,
    GDK_MOUSE               = 84,
    GDK_PENCIL              = 86,
    GDK_PIRATE              = 88,
    GDK_PLUS                = 90,
    GDK_QUESTION_ARROW      = 92,
    GDK_RIGHT_PTR           = 94,
    GDK_RIGHT_SIDE          = 96,
    GDK_RIGHT_TEE           = 98,
    GDK_RIGHTBUTTON         = 100,
    GDK_RTL_LOGO            = 102,
    GDK_SAILBOAT            = 104,
    GDK_SB_DOWN_ARROW       = 106,
    GDK_SB_H_DOUBLE_ARROW   = 108,
    GDK_SB_LEFT_ARROW       = 110,
    GDK_SB_RIGHT_ARROW      = 112,
    GDK_SB_UP_ARROW         = 114,
    GDK_SB_V_DOUBLE_ARROW   = 116,
    GDK_SHUTTLE             = 118,
    GDK_SIZING              = 120,
    GDK_SPIDER              = 122,
    GDK_SPRAYCAN            = 124,
    GDK_STAR                = 126,
    GDK_TARGET              = 128,
    GDK_TCROSS              = 130,
    GDK_TOP_LEFT_ARROW      = 132,
    GDK_TOP_LEFT_CORNER     = 134,
    GDK_TOP_RIGHT_CORNER    = 136,
    GDK_TOP_SIDE            = 138,
    GDK_TOP_TEE             = 140,
    GDK_TREK                = 142,
    GDK_UL_ANGLE            = 144,
    GDK_UMBRELLA            = 146,
    GDK_UR_ANGLE            = 148,
    GDK_WATCH               = 150,
    GDK_XTERM               = 152,
    GDK_LAST_CURSOR,
    GDK_BLANK_CURSOR        = -2,
    GDK_CURSOR_IS_PIXMAP    = -1
  } GdkCursorType;

  GdkCursor * gdk_cursor_new (GdkCursorType cursor_type);

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

  GdkCursor * gdk_window_get_cursor (GdkWindow *window);
  void gdk_window_set_cursor (GdkWindow *window, GdkCursor *cursor);

  /* GdkDevice */
  typedef struct {} GdkDevice;

  typedef struct {
    GdkEventType type;
    GdkWindow *window;
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

  typedef struct {
    GdkEventType type;
    GdkWindow *window;
    gint8 send_event;
    guint32 time;
    gdouble x;
    gdouble y;
    gdouble *axes;
    guint state;
    guint button;
    GdkDevice *device;
    gdouble x_root, y_root;
  } GdkEventButton;

  typedef struct {
    GdkEventType type;
    GdkWindow *window;
    gint8 send_event;
    guint32 time;
    gdouble x;
    gdouble y;
    gdouble *axes;
    guint state;
    gint16 is_hint;
    GdkDevice *device;
    gdouble x_root, y_root;
  } GdkEventMotion;

  typedef struct {
    GdkEventType type;
    GdkWindow *window;
    gint8 send_event;
    guint32 time;
    gdouble x;
    gdouble y;
    guint state;
    GdkScrollDirection direction;
    GdkDevice *device;
    gdouble x_root, y_root;
    gdouble delta_x;
    gdouble delta_y;
  } GdkEventScroll;

  /* GdkPixbuf */
  typedef struct {} GdkPixbuf;

  GdkPixbuf * gdk_pixbuf_get_from_window (GdkWindow *window,
                                          gint src_x,
                                          gint src_y,
                                          gint width,
                                          gint height);

  gboolean gdk_pixbuf_savev (GdkPixbuf *pixbuf,
                             const char *filename,
                             const char *type,
                             char **option_keys,
                             char **option_values,
                             GError **error);

  /* GdkAtom

  This is really an opaque struct, but we're going to have to break the
  abstraction here, as it's ret-by-value */
  typedef struct { gulong val; } GdkAtom;
  GdkAtom gdk_atom_intern (const gchar *atom_name, gboolean only_if_exists);
  gchar * gdk_atom_name (GdkAtom atom);
]]
