-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
require 'ljglibs.cdefs.glib'

require 'ljglibs.cdefs.cairo'
-- require 'ljglibs.cdefs.gio'

ffi.cdef [[
  /* PangoContext */
  typedef struct {} PangoContext;

  /* PangoLayout */
  typedef struct {} PangoLayout;

  typedef struct {
    int x;
    int y;
    int width;
    int height;
  } PangoRectangle;

  PangoLayout * pango_layout_new (PangoContext *context);
  void pango_layout_set_text (PangoLayout *layout, const char *text, int length);
  void pango_layout_get_pixel_size (PangoLayout *layout, int *width, int *height);
  void pango_layout_index_to_pos (PangoLayout *layout, int index, PangoRectangle *pos);

  /* PangoCairo */
  PangoContext * pango_cairo_create_context (cairo_t *cr);
  PangoLayout * pango_cairo_create_layout (cairo_t *cr);
  void pango_cairo_show_layout (cairo_t *cr, PangoLayout *layout);
]]
