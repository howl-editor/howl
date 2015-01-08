-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'
require 'ljglibs.cdefs.glib'
require 'ljglibs.cdefs.cairo'

ffi.cdef [[

  /* PangoFontDescription */
  typedef struct {} PangoFontDescription;

  PangoFontDescription * pango_font_description_new (void);
  void pango_font_description_free (PangoFontDescription *desc);
  void pango_font_description_set_family (PangoFontDescription *desc, const char *family);
  const char * pango_font_description_get_family (const PangoFontDescription *desc);
  void pango_font_description_set_size (PangoFontDescription *desc, gint size);
  gint pango_font_description_get_size (const PangoFontDescription *desc);
  void pango_font_description_set_absolute_size (PangoFontDescription *desc, double size);
  gboolean pango_font_description_get_size_is_absolute (const PangoFontDescription *desc);
  PangoFontDescription * pango_font_description_from_string (const char *str);
  char * pango_font_description_to_string (const PangoFontDescription *desc);

  /* PangoTabArray */
  typedef enum {
    PANGO_TAB_LEFT
  } PangoTabAlign;

  typedef struct {} PangoTabArray;
  PangoTabArray * pango_tab_array_new (gint initial_size, gboolean positions_in_pixels);
  PangoTabArray * pango_tab_array_new_with_positions (gint size,
                                                      gboolean positions_in_pixels,
                                                      PangoTabAlign first_alignment,
                                                      gint first_position,
                                                      ...);

  void pango_tab_array_free (PangoTabArray *tab_array);
  gint pango_tab_array_get_size (PangoTabArray *tab_array);

  void pango_tab_array_set_tab (PangoTabArray *tab_array,
                                gint tab_index,
                                PangoTabAlign alignment,
                                gint location);

  void pango_tab_array_get_tab (PangoTabArray *tab_array,
                                gint tab_index,
                                PangoTabAlign *alignment,
                                gint *location);

  gboolean pango_tab_array_get_positions_in_pixels (PangoTabArray *tab_array);

  /* PangoContext */
  typedef struct {} PangoContext;

  PangoFontDescription * pango_context_get_font_description (PangoContext *context);
  void pango_context_set_font_description (PangoContext *context, const PangoFontDescription *desc);

  typedef struct {
    int x;
    int y;
    int width;
    int height;
  } PangoRectangle;

  typedef enum {
    PANGO_ALIGN_LEFT,
    PANGO_ALIGN_CENTER,
    PANGO_ALIGN_RIGHT
  } PangoAlignment;

  /* PangoColor */
  typedef struct {
    guint16 red;
    guint16 green;
    guint16 blue;
  } PangoColor;

  gboolean pango_color_parse (PangoColor *color, const char *spec);
  gchar * pango_color_to_string (const PangoColor *color);

  /* Attributes */
  typedef enum {
    PANGO_ATTR_INDEX_FROM_TEXT_BEGINNING = 0,
    PANGO_ATTR_INDEX_TO_TEXT_END = 4294967295 // fix me
  } PangoAttributeConstants;

  typedef enum
  {
    PANGO_ATTR_INVALID,           /* 0 is an invalid attribute type */
    PANGO_ATTR_LANGUAGE,		/* PangoAttrLanguage */
    PANGO_ATTR_FAMILY,		/* PangoAttrString */
    PANGO_ATTR_STYLE,		/* PangoAttrInt */
    PANGO_ATTR_WEIGHT,		/* PangoAttrInt */
    PANGO_ATTR_VARIANT,		/* PangoAttrInt */
    PANGO_ATTR_STRETCH,		/* PangoAttrInt */
    PANGO_ATTR_SIZE,		/* PangoAttrSize */
    PANGO_ATTR_FONT_DESC,		/* PangoAttrFontDesc */
    PANGO_ATTR_FOREGROUND,	/* PangoAttrColor */
    PANGO_ATTR_BACKGROUND,	/* PangoAttrColor */
    PANGO_ATTR_UNDERLINE,		/* PangoAttrInt */
    PANGO_ATTR_STRIKETHROUGH,	/* PangoAttrInt */
    PANGO_ATTR_RISE,		/* PangoAttrInt */
    PANGO_ATTR_SHAPE,		/* PangoAttrShape */
    PANGO_ATTR_SCALE,             /* PangoAttrFloat */
    PANGO_ATTR_FALLBACK,          /* PangoAttrInt */
    PANGO_ATTR_LETTER_SPACING,    /* PangoAttrInt */
    PANGO_ATTR_UNDERLINE_COLOR,	/* PangoAttrColor */
    PANGO_ATTR_STRIKETHROUGH_COLOR,/* PangoAttrColor */
    PANGO_ATTR_ABSOLUTE_SIZE,	/* PangoAttrSize */
    PANGO_ATTR_GRAVITY,		/* PangoAttrInt */
    PANGO_ATTR_GRAVITY_HINT	/* PangoAttrInt */
  } PangoAttrType;

  typedef enum {
    PANGO_STYLE_NORMAL,
    PANGO_STYLE_OBLIQUE,
    PANGO_STYLE_ITALIC
  } PangoStyle;

  typedef enum {
    PANGO_VARIANT_NORMAL,
    PANGO_VARIANT_SMALL_CAPS
  } PangoVariant;

  typedef enum {
    PANGO_WEIGHT_THIN = 100,
    PANGO_WEIGHT_ULTRALIGHT = 200,
    PANGO_WEIGHT_LIGHT = 300,
    PANGO_WEIGHT_BOOK = 380,
    PANGO_WEIGHT_NORMAL = 400,
    PANGO_WEIGHT_MEDIUM = 500,
    PANGO_WEIGHT_SEMIBOLD = 600,
    PANGO_WEIGHT_BOLD = 700,
    PANGO_WEIGHT_ULTRABOLD = 800,
    PANGO_WEIGHT_HEAVY = 900,
    PANGO_WEIGHT_ULTRAHEAVY = 1000
  } PangoWeight;

  typedef enum {
    PANGO_STRETCH_ULTRA_CONDENSED,
    PANGO_STRETCH_EXTRA_CONDENSED,
    PANGO_STRETCH_CONDENSED,
    PANGO_STRETCH_SEMI_CONDENSED,
    PANGO_STRETCH_NORMAL,
    PANGO_STRETCH_SEMI_EXPANDED,
    PANGO_STRETCH_EXPANDED,
    PANGO_STRETCH_EXTRA_EXPANDED,
    PANGO_STRETCH_ULTRA_EXPANDED
  } PangoStretch;

  typedef enum {
    PANGO_FONT_MASK_FAMILY  = 1 << 0,
    PANGO_FONT_MASK_STYLE   = 1 << 1,
    PANGO_FONT_MASK_VARIANT = 1 << 2,
    PANGO_FONT_MASK_WEIGHT  = 1 << 3,
    PANGO_FONT_MASK_STRETCH = 1 << 4,
    PANGO_FONT_MASK_SIZE    = 1 << 5,
    PANGO_FONT_MASK_GRAVITY = 1 << 6
  } PangoFontMask;

  typedef enum {
    PANGO_UNDERLINE_NONE,
    PANGO_UNDERLINE_SINGLE,
    PANGO_UNDERLINE_DOUBLE,
    PANGO_UNDERLINE_LOW,
    PANGO_UNDERLINE_ERROR
  } PangoUnderline;

  typedef enum {
    PANGO_GRAVITY_SOUTH,
    PANGO_GRAVITY_EAST,
    PANGO_GRAVITY_NORTH,
    PANGO_GRAVITY_WEST,
    PANGO_GRAVITY_AUTO
  } PangoGravity;

  typedef enum {
    PANGO_GRAVITY_HINT_NATURAL,
    PANGO_GRAVITY_HINT_STRONG,
    PANGO_GRAVITY_HINT_LINE
  } PangoGravityHint;

  typedef struct {} _PangoAttribute;

  typedef struct {
    PangoAttrType type;
    _PangoAttribute * (*copy) (const _PangoAttribute *attr);
    void             (*destroy) (_PangoAttribute *attr);
    gboolean         (*equal) (const _PangoAttribute *attr1, const _PangoAttribute *attr2);
  } PangoAttrClass;

  typedef struct {
    const PangoAttrClass *klass;
    guint start_index; /* in bytes */
    guint end_index; /* in bytes. The character at this index is not included */
  } PangoAttribute;

  typedef struct {
    PangoAttribute attr;
    char *value;
  } PangoAttrString;

  typedef struct {
    PangoAttribute attr;
    int value;
  } PangoAttrInt;

  typedef struct {
    PangoAttribute attr;
    double value;
  } PangoAttrFloat;

  typedef struct {
    PangoAttribute attr;
    int size;
    guint absolute : 1;
  } PangoAttrSize;

  typedef struct {
    PangoAttribute attr;
    PangoColor color;
  } PangoAttrColor;

  typedef struct {
    PangoAttrColor color;
  } PangoAttributeForeground;

  typedef struct {
    PangoAttribute attr;
    PangoFontDescription *desc;
  } PangoAttrFontDesc;

  void pango_attribute_destroy (PangoAttribute *attr);
  PangoAttribute * pango_attribute_copy (const PangoAttribute *attr);

  PangoAttrColor * pango_attr_foreground_new (guint16 red,
                                              guint16 green,
                                              guint16 blue);
  PangoAttrColor * pango_attr_background_new (guint16 red,
                                              guint16 green,
                                              guint16 blue);
  PangoAttrString * pango_attr_family_new (const char *family);
  PangoAttrInt * pango_attr_style_new (PangoStyle style);
  PangoAttrInt * pango_attr_variant_new (PangoVariant variant);
  PangoAttrInt * pango_attr_stretch_new (PangoStretch stretch);
  PangoAttrInt * pango_attr_weight_new (PangoWeight weight);
  PangoAttrInt * pango_attr_size_new (int size);
  PangoAttrInt * pango_attr_size_new_absolute (int size);
  PangoAttribute * pango_attr_font_desc_new (const PangoFontDescription *desc);
  PangoAttrInt * pango_attr_strikethrough_new (gboolean strikethrough);
  PangoAttrColor * pango_attr_strikethrough_color_new (guint16 red,
                                                       guint16 green,
                                                       guint16 blue);
  PangoAttrInt * pango_attr_underline_new (PangoUnderline underline);
  PangoAttrColor *pango_attr_underline_color_new (guint16 red,
                                                  guint16 green,
                                                  guint16 blue);
  PangoAttrInt * pango_attr_rise_new (int rise);
  PangoAttrFloat * pango_attr_scale_new (double scale_factor);
  PangoAttrInt * pango_attr_fallback_new (gboolean enable_fallback);
  PangoAttrInt * pango_attr_letter_spacing_new (int letter_spacing);
  PangoAttribute * pango_attr_shape_new (const PangoRectangle *ink_rect,
                                         const PangoRectangle *logical_rect);
  PangoAttrInt * pango_attr_gravity_new      (PangoGravity     gravity);
  PangoAttrInt * pango_attr_gravity_hint_new (PangoGravityHint hint);

  typedef struct {} PangoAttrList;

  PangoAttrList * pango_attr_list_new (void);
  void pango_attr_list_unref (PangoAttrList *list);
  void pango_attr_list_insert (PangoAttrList *list, PangoAttribute *attr);
  void pango_attr_list_insert_before (PangoAttrList *list, PangoAttribute *attr);
  void pango_attr_list_change (PangoAttrList *list, PangoAttribute *attr);

  typedef struct {} PangoAttrIterator;
  PangoAttrIterator * pango_attr_list_get_iterator (PangoAttrList *list);
  void pango_attr_iterator_destroy (PangoAttrIterator *iterator);
  gboolean pango_attr_iterator_next (PangoAttrIterator *iterator);
  void pango_attr_iterator_range (PangoAttrIterator *iterator,
                                  gint *start,
                                  gint *end);
  PangoAttribute * pango_attr_iterator_get (PangoAttrIterator *iterator,
                                            PangoAttrType type);

  /* PangoLayout */

  typedef struct {} PangoLayout;

  typedef struct {
    PangoLayout *layout;
    gint         start_index;     /* start of line as byte index into layout->text */
    gint         length;		/* length of line in bytes */
    void         *runs;
    //GSList      *runs;
    guint        is_paragraph_start : 1;  /* TRUE if this is the first line of the paragraph */
    guint        resolved_dir : 3;  /* Resolved PangoDirection of line */
  } PangoLayoutLine;

  typedef struct {} PangoLayoutIter;

  PangoLayout * pango_layout_new (PangoContext *context);
  void pango_layout_set_text (PangoLayout *layout, const char *text, int length);
  const char *pango_layout_get_text (PangoLayout *layout);
  void pango_layout_get_pixel_size (PangoLayout *layout, int *width, int *height);
  void pango_layout_set_alignment (PangoLayout *layout, PangoAlignment alignment);
  PangoAlignment pango_layout_get_alignment (PangoLayout *layout);
  void pango_layout_set_width (PangoLayout *layout, int width);
  int pango_layout_get_width (PangoLayout *layout);
  void pango_layout_set_height (PangoLayout *layout, int height);
  int pango_layout_get_height (PangoLayout *layout);
  void pango_layout_set_spacing (PangoLayout *layout, int spacing);
  int pango_layout_get_spacing (PangoLayout *layout);
  void pango_layout_set_attributes (PangoLayout *layout, PangoAttrList *attrs);
  PangoAttrList * pango_layout_get_attributes (PangoLayout *layout);
  void pango_layout_set_font_description (PangoLayout *layout, const PangoFontDescription *desc);
  const PangoFontDescription * pango_layout_get_font_description (PangoLayout *layout);
  int pango_layout_get_baseline (PangoLayout *layout);

  void pango_layout_index_to_pos (PangoLayout *layout, int index, PangoRectangle *pos);

  gboolean pango_layout_xy_to_index (PangoLayout *layout,
                                     int x,
                                     int y,
                                     int *index_,
                                     int *trailing);

  void pango_layout_index_to_line_x (PangoLayout *layout,
                                     int index_,
                                     gboolean trailing,
                                     int *line,
                                     int *x_pos);

  void pango_layout_move_cursor_visually (PangoLayout *layout,
                                          gboolean strong,
                                          int old_index,
                                          int old_trailing,
                                          int direction,
                                          int *new_index,
                                          int *new_trailing);

  /* PangoLayoutLine */
  PangoLayoutLine * pango_layout_line_ref (PangoLayoutLine *line);
  void pango_layout_line_unref (PangoLayoutLine *line);
  PangoLayoutLine * pango_layout_get_line (PangoLayout *layout, int line);
  PangoLayoutLine * pango_layout_get_line_readonly (PangoLayout *layout, int line);
  void pango_layout_line_get_pixel_extents (PangoLayoutLine *layout_line,
                                     PangoRectangle *ink_rect,
                                     PangoRectangle *logical_rect);

  /* PangoLayoutIter */
  PangoLayoutIter * pango_layout_get_iter (PangoLayout *layout);
  void pango_layout_iter_free (PangoLayoutIter *iter);
  gboolean pango_layout_iter_next_line (PangoLayoutIter *iter);
  gboolean pango_layout_iter_at_last_line (PangoLayoutIter *iter);
  int pango_layout_iter_get_baseline (PangoLayoutIter *iter);
  PangoLayoutLine * pango_layout_iter_get_line (PangoLayoutIter *iter);
  PangoLayoutLine * pango_layout_iter_get_line_readonly (PangoLayoutIter *iter);
  void pango_layout_iter_get_line_yrange (PangoLayoutIter *iter,
                                   int *y0_,
                                   int *y1_);

  void pango_layout_set_tabs (PangoLayout *layout, PangoTabArray *tabs);
  PangoTabArray * pango_layout_get_tabs (PangoLayout *layout);

  /* PangoCairo */
  PangoContext * pango_cairo_create_context (cairo_t *cr);
  PangoLayout * pango_cairo_create_layout (cairo_t *cr);
  void pango_cairo_show_layout (cairo_t *cr, PangoLayout *layout);
]]
