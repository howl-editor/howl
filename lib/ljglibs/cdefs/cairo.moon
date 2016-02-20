-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'

ffi.cdef [[

  typedef enum {
    CAIRO_CONTENT_COLOR		= 0x1000,
    CAIRO_CONTENT_ALPHA		= 0x2000,
    CAIRO_CONTENT_COLOR_ALPHA = 0x3000
  } cairo_content_t;

  typedef enum {
    CAIRO_ANTIALIAS_DEFAULT,

    /* method */
    CAIRO_ANTIALIAS_NONE,
    CAIRO_ANTIALIAS_GRAY,
    CAIRO_ANTIALIAS_SUBPIXEL,

    /* hints */
    CAIRO_ANTIALIAS_FAST,
    CAIRO_ANTIALIAS_GOOD,
    CAIRO_ANTIALIAS_BEST
  } cairo_antialias_t;

  typedef enum {
    CAIRO_FILL_RULE_WINDING,
    CAIRO_FILL_RULE_EVEN_ODD
  } cairo_fill_rule_t;

  typedef enum {
    CAIRO_LINE_CAP_BUTT,
    CAIRO_LINE_CAP_ROUND,
    CAIRO_LINE_CAP_SQUARE
  } cairo_line_cap_t;

  typedef enum {
    CAIRO_LINE_JOIN_MITER,
    CAIRO_LINE_JOIN_ROUND,
    CAIRO_LINE_JOIN_BEVEL
  } cairo_line_join_t;

  typedef enum {
    CAIRO_OPERATOR_CLEAR,

    CAIRO_OPERATOR_SOURCE,
    CAIRO_OPERATOR_OVER,
    CAIRO_OPERATOR_IN,
    CAIRO_OPERATOR_OUT,
    CAIRO_OPERATOR_ATOP,

    CAIRO_OPERATOR_DEST,
    CAIRO_OPERATOR_DEST_OVER,
    CAIRO_OPERATOR_DEST_IN,
    CAIRO_OPERATOR_DEST_OUT,
    CAIRO_OPERATOR_DEST_ATOP,

    CAIRO_OPERATOR_XOR,
    CAIRO_OPERATOR_ADD,
    CAIRO_OPERATOR_SATURATE,

    CAIRO_OPERATOR_MULTIPLY,
    CAIRO_OPERATOR_SCREEN,
    CAIRO_OPERATOR_OVERLAY,
    CAIRO_OPERATOR_DARKEN,
    CAIRO_OPERATOR_LIGHTEN,
    CAIRO_OPERATOR_COLOR_DODGE,
    CAIRO_OPERATOR_COLOR_BURN,
    CAIRO_OPERATOR_HARD_LIGHT,
    CAIRO_OPERATOR_SOFT_LIGHT,
    CAIRO_OPERATOR_DIFFERENCE,
    CAIRO_OPERATOR_EXCLUSION,
    CAIRO_OPERATOR_HSL_HUE,
    CAIRO_OPERATOR_HSL_SATURATION,
    CAIRO_OPERATOR_HSL_COLOR,
    CAIRO_OPERATOR_HSL_LUMINOSITY
  } cairo_operator_t;

  typedef enum {
    CAIRO_STATUS_SUCCESS = 0,

    CAIRO_STATUS_NO_MEMORY,
    CAIRO_STATUS_INVALID_RESTORE,
    CAIRO_STATUS_INVALID_POP_GROUP,
    CAIRO_STATUS_NO_CURRENT_POINT,
    CAIRO_STATUS_INVALID_MATRIX,
    CAIRO_STATUS_INVALID_STATUS,
    CAIRO_STATUS_NULL_POINTER,
    CAIRO_STATUS_INVALID_STRING,
    CAIRO_STATUS_INVALID_PATH_DATA,
    CAIRO_STATUS_READ_ERROR,
    CAIRO_STATUS_WRITE_ERROR,
    CAIRO_STATUS_SURFACE_FINISHED,
    CAIRO_STATUS_SURFACE_TYPE_MISMATCH,
    CAIRO_STATUS_PATTERN_TYPE_MISMATCH,
    CAIRO_STATUS_INVALID_CONTENT,
    CAIRO_STATUS_INVALID_FORMAT,
    CAIRO_STATUS_INVALID_VISUAL,
    CAIRO_STATUS_FILE_NOT_FOUND,
    CAIRO_STATUS_INVALID_DASH,
    CAIRO_STATUS_INVALID_DSC_COMMENT,
    CAIRO_STATUS_INVALID_INDEX,
    CAIRO_STATUS_CLIP_NOT_REPRESENTABLE,
    CAIRO_STATUS_TEMP_FILE_ERROR,
    CAIRO_STATUS_INVALID_STRIDE,
    CAIRO_STATUS_FONT_TYPE_MISMATCH,
    CAIRO_STATUS_USER_FONT_IMMUTABLE,
    CAIRO_STATUS_USER_FONT_ERROR,
    CAIRO_STATUS_NEGATIVE_COUNT,
    CAIRO_STATUS_INVALID_CLUSTERS,
    CAIRO_STATUS_INVALID_SLANT,
    CAIRO_STATUS_INVALID_WEIGHT,
    CAIRO_STATUS_INVALID_SIZE,
    CAIRO_STATUS_USER_FONT_NOT_IMPLEMENTED,
    CAIRO_STATUS_DEVICE_TYPE_MISMATCH,
    CAIRO_STATUS_DEVICE_ERROR,
    CAIRO_STATUS_INVALID_MESH_CONSTRUCTION,
    CAIRO_STATUS_DEVICE_FINISHED,
    CAIRO_STATUS_JBIG2_GLOBAL_MISSING,

    CAIRO_STATUS_LAST_STATUS
  } cairo_status_t;

  typedef enum {
      CAIRO_EXTEND_NONE,
      CAIRO_EXTEND_REPEAT,
      CAIRO_EXTEND_REFLECT,
      CAIRO_EXTEND_PAD
  } cairo_extend_t;

  typedef struct {} cairo_t;
  typedef struct {} cairo_surface_t;
  typedef struct {} cairo_pattern_t;

  typedef int cairo_bool_t;

  typedef struct {
    double x, y, width, height;
  } cairo_rectangle_t;

  typedef struct {
      int x, y;
      int width, height;
  } cairo_rectangle_int_t;

  typedef struct {
      int unused;
  } cairo_user_data_key_t;

  typedef struct {
    cairo_status_t     status;
    cairo_rectangle_t *rectangles;
    int                num_rectangles;
  } cairo_rectangle_list_t;

  typedef void  (*cairo_destroy_func_t) (void *data);

  cairo_t *           cairo_create                        (cairo_surface_t *target);
  cairo_t *           cairo_reference                     (cairo_t *cr);
  void                cairo_destroy                       (cairo_t *cr);
  cairo_status_t      cairo_status                        (cairo_t *cr);
  void                cairo_save                          (cairo_t *cr);
  void                cairo_restore                       (cairo_t *cr);
  cairo_surface_t *   cairo_get_target                    (cairo_t *cr);
  void                cairo_push_group                    (cairo_t *cr);
  void                cairo_push_group_with_content       (cairo_t *cr,
                                                           cairo_content_t content);
  cairo_pattern_t *   cairo_pop_group                     (cairo_t *cr);
  void                cairo_pop_group_to_source           (cairo_t *cr);
  cairo_surface_t *   cairo_get_group_target              (cairo_t *cr);
  void                cairo_set_source_rgb                (cairo_t *cr,
                                                           double red,
                                                           double green,
                                                           double blue);
  void                cairo_set_source_rgba               (cairo_t *cr,
                                                           double red,
                                                           double green,
                                                           double blue,
                                                           double alpha);
  void                cairo_set_source                    (cairo_t *cr,
                                                           cairo_pattern_t *source);
  void                cairo_set_source_surface            (cairo_t *cr,
                                                           cairo_surface_t *surface,
                                                           double x,
                                                           double y);
  cairo_pattern_t *   cairo_get_source                    (cairo_t *cr);
  enum                cairo_antialias_t;
  void                cairo_set_antialias                 (cairo_t *cr,
                                                           cairo_antialias_t antialias);
  cairo_antialias_t   cairo_get_antialias                 (cairo_t *cr);
  void                cairo_set_dash                      (cairo_t *cr,
                                                           const double *dashes,
                                                           int num_dashes,
                                                           double offset);
  int                 cairo_get_dash_count                (cairo_t *cr);
  void                cairo_get_dash                      (cairo_t *cr,
                                                           double *dashes,
                                                           double *offset);
  enum                cairo_fill_rule_t;
  void                cairo_set_fill_rule                 (cairo_t *cr,
                                                           cairo_fill_rule_t fill_rule);
  cairo_fill_rule_t   cairo_get_fill_rule                 (cairo_t *cr);
  enum                cairo_line_cap_t;
  void                cairo_set_line_cap                  (cairo_t *cr,
                                                           cairo_line_cap_t line_cap);
  cairo_line_cap_t    cairo_get_line_cap                  (cairo_t *cr);
  enum                cairo_line_join_t;
  void                cairo_set_line_join                 (cairo_t *cr,
                                                           cairo_line_join_t line_join);
  cairo_line_join_t   cairo_get_line_join                 (cairo_t *cr);
  void                cairo_set_line_width                (cairo_t *cr,
                                                           double width);
  double              cairo_get_line_width                (cairo_t *cr);
  void                cairo_set_miter_limit               (cairo_t *cr,
                                                           double limit);
  double              cairo_get_miter_limit               (cairo_t *cr);
  enum                cairo_operator_t;
  void                cairo_set_operator                  (cairo_t *cr,
                                                           cairo_operator_t op);
  cairo_operator_t    cairo_get_operator                  (cairo_t *cr);
  void                cairo_set_tolerance                 (cairo_t *cr,
                                                           double tolerance);
  double              cairo_get_tolerance                 (cairo_t *cr);
  void                cairo_clip                          (cairo_t *cr);
  void                cairo_clip_preserve                 (cairo_t *cr);
  void                cairo_clip_extents                  (cairo_t *cr,
                                                           double *x1,
                                                           double *y1,
                                                           double *x2,
                                                           double *y2);
  cairo_bool_t        cairo_in_clip                       (cairo_t *cr,
                                                           double x,
                                                           double y);
  void                cairo_reset_clip                    (cairo_t *cr);
                      cairo_rectangle_t;
                      cairo_rectangle_list_t;
  void                cairo_rectangle_list_destroy        (cairo_rectangle_list_t *rectangle_list);
  cairo_rectangle_list_t * cairo_copy_clip_rectangle_list (cairo_t *cr);
  void                cairo_fill                          (cairo_t *cr);
  void                cairo_fill_preserve                 (cairo_t *cr);
  void                cairo_fill_extents                  (cairo_t *cr,
                                                           double *x1,
                                                           double *y1,
                                                           double *x2,
                                                           double *y2);
  cairo_bool_t        cairo_in_fill                       (cairo_t *cr,
                                                           double x,
                                                           double y);
  void                cairo_mask                          (cairo_t *cr,
                                                           cairo_pattern_t *pattern);
  void                cairo_mask_surface                  (cairo_t *cr,
                                                           cairo_surface_t *surface,
                                                           double surface_x,
                                                           double surface_y);
  void                cairo_paint                         (cairo_t *cr);
  void                cairo_paint_with_alpha              (cairo_t *cr,
                                                           double alpha);
  void                cairo_stroke                        (cairo_t *cr);
  void                cairo_stroke_preserve               (cairo_t *cr);
  void                cairo_stroke_extents                (cairo_t *cr,
                                                           double *x1,
                                                           double *y1,
                                                           double *x2,
                                                           double *y2);
  cairo_bool_t        cairo_in_stroke                     (cairo_t *cr,
                                                           double x,
                                                           double y);
  void                cairo_copy_page                     (cairo_t *cr);
  void                cairo_show_page                     (cairo_t *cr);
  unsigned int        cairo_get_reference_count           (cairo_t *cr);
  cairo_status_t      cairo_set_user_data                 (cairo_t *cr,
                                                           const cairo_user_data_key_t *key,
                                                           void *user_data,
                                                           cairo_destroy_func_t destroy);
  void *              cairo_get_user_data                 (cairo_t *cr,
                                                           const cairo_user_data_key_t *key);

  /* Path stuff */
  typedef enum {
    CAIRO_PATH_MOVE_TO,
    CAIRO_PATH_LINE_TO,
    CAIRO_PATH_CURVE_TO,
    CAIRO_PATH_CLOSE_PATH
  } cairo_path_data_type_t;

  typedef union _cairo_path_data_t {
    struct {
	cairo_path_data_type_t type;
	int length;
    } header;
    struct {
	double x, y;
    } point;
  } cairo_path_data_t;

  typedef struct {
    cairo_status_t status;
    cairo_path_data_t *data;
    int num_data;
  } cairo_path_t;

  typedef struct {
    unsigned long        index;
    double               x;
    double               y;
  } cairo_glyph_t;

  cairo_path_t *      cairo_copy_path                     (cairo_t *cr);
  cairo_path_t *      cairo_copy_path_flat                (cairo_t *cr);
  void                cairo_path_destroy                  (cairo_path_t *path);
  void                cairo_append_path                   (cairo_t *cr,
                                                           const cairo_path_t *path);
  cairo_bool_t        cairo_has_current_point             (cairo_t *cr);
  void                cairo_get_current_point             (cairo_t *cr,
                                                           double *x,
                                                           double *y);
  void                cairo_new_path                      (cairo_t *cr);
  void                cairo_new_sub_path                  (cairo_t *cr);
  void                cairo_close_path                    (cairo_t *cr);
  void                cairo_arc                           (cairo_t *cr,
                                                           double xc,
                                                           double yc,
                                                           double radius,
                                                           double angle1,
                                                           double angle2);
  void                cairo_arc_negative                  (cairo_t *cr,
                                                           double xc,
                                                           double yc,
                                                           double radius,
                                                           double angle1,
                                                           double angle2);
  void                cairo_curve_to                      (cairo_t *cr,
                                                           double x1,
                                                           double y1,
                                                           double x2,
                                                           double y2,
                                                           double x3,
                                                           double y3);
  void                cairo_line_to                       (cairo_t *cr,
                                                           double x,
                                                           double y);
  void                cairo_move_to                       (cairo_t *cr,
                                                           double x,
                                                           double y);
  void                cairo_rectangle                     (cairo_t *cr,
                                                           double x,
                                                           double y,
                                                           double width,
                                                           double height);
  void                cairo_glyph_path                    (cairo_t *cr,
                                                           const cairo_glyph_t *glyphs,
                                                           int num_glyphs);
  void                cairo_text_path                     (cairo_t *cr,
                                                           const char *utf8);
  void                cairo_rel_curve_to                  (cairo_t *cr,
                                                           double dx1,
                                                           double dy1,
                                                           double dx2,
                                                           double dy2,
                                                           double dx3,
                                                           double dy3);
  void                cairo_rel_line_to                   (cairo_t *cr,
                                                           double dx,
                                                           double dy);
  void                cairo_rel_move_to                   (cairo_t *cr,
                                                           double dx,
                                                           double dy);
  void                cairo_path_extents                  (cairo_t *cr,
                                                           double *x1,
                                                           double *y1,
                                                           double *x2,
                                                           double *y2);

  /* Surface and friend */
  cairo_surface_t *
  cairo_surface_create_similar (cairo_surface_t  *other,
                                cairo_content_t	content,
                                int width,
                                int	height);



  void cairo_surface_destroy (cairo_surface_t *surface);

  cairo_status_t cairo_surface_write_to_png (cairo_surface_t *surface,
                                             const char *filename);

  /* patterns */
  cairo_pattern_t * cairo_pattern_reference (cairo_pattern_t *pattern);
  void cairo_pattern_destroy (cairo_pattern_t *pattern);

  void cairo_pattern_set_extend (cairo_pattern_t *pattern, cairo_extend_t extend);
  cairo_extend_t cairo_pattern_get_extend (cairo_pattern_t *pattern);

  cairo_pattern_t * cairo_pattern_create_linear (double x0,
                                                 double y0,
                                                 double x1,
                                                 double y1);

  void cairo_pattern_add_color_stop_rgba (cairo_pattern_t *pattern,
                                          double offset,
                                          double red,
                                          double green,
                                          double blue,
                                          double alpha);

  /* transformations */
  void cairo_translate (cairo_t *cr, double tx, double ty);


]]
