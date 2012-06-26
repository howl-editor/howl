------------------------------------------------------------------------------
--
--  LGI Cairo override module.
--
--  Copyright (c) 2012 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local assert, pairs, ipairs, setmetatable, table, rawget
   = assert, pairs, ipairs, setmetatable, table, rawget
local lgi = require 'lgi'
local cairo = lgi.cairo

local core = require 'lgi.core'
local ffi = require 'lgi.ffi'
local component = require 'lgi.component'
local record = require 'lgi.record'
local enum = require 'lgi.enum'
local ti = ffi.types

cairo._module = core.module('cairo', 2)
local module_gobject = core.gi.cairo.resolve

-- Load some constants.
cairo._constant = {
   MIME_TYPE_JP2 = 'image/jp2',
   MIME_TYPE_JPEG = 'image/jpeg',
   MIME_TYPE_PNG = 'image/png',
   MIME_TYPE_URI = 'text/x-uri',
}

-- Load definitions of all enums.
cairo._enum = cairo._enum or {}
for _, name in pairs {
   'Status', 'Content', 'Operator', 'Antialias', 'FillRule', 'LineCap',
   'LineJoin', 'TextClusterFlags', 'FontSlant', 'FontWeight', 'SubpixelOrder',
   'HintStyle', 'HintMetrics', 'FontType', 'PathDataType', 'DeviceType',
   'SurfaceType', 'Format', 'PatternType', 'Extend', 'Filter', 'RegionOverlap',
   'PdfVersion', 'PsLevel', 'SvgVersion',
} do
   local lower = name:gsub('([%l%d])([%u])', '%1_%2'):lower()
   local gtype = ffi.load_gtype(
      module_gobject, 'cairo_gobject_' .. lower .. '_get_type')
   if gtype then
      cairo._enum[name] = ffi.load_enum(gtype, 'cairo.' .. name)
   else
      cairo._enum[name] = component.create(nil, enum.enum_mt, 'cairo.' .. name)
   end
end

-- Load definitions of all boxed records.
cairo._struct = cairo._struct or {}
for _, struct in pairs {
   'Context', 'Device', 'Surface', 'Rectangle', 'ScaledFont', 'FontFace',
   'FontOptions', 'Region', 'RectangleInt', 'Path', 'TextExtents',
   'FontExtents', 'Matrix', 'ImageSurface', 'PdfSurface', 'PsSurface',
   'RecordingSurface', 'SvgSurface', 'ToyFontFace', 'RectangleList',
} do
   local lower = struct:gsub('([%l%d])([%u])', '%1_%2'):lower()
   local gtype = ffi.load_gtype(
      module_gobject, 'cairo_gobject_' .. lower .. '_get_type')
   local obj = component.create(gtype, record.struct_mt, 'cairo.' .. struct)
   cairo._struct[struct] = obj
end

local path_data_header = component.create(nil, record.struct_mt)
ffi.load_fields(path_data_header, { { 'type', cairo.PathDataType },
				    { 'length', ti.int } })
local path_data_point = component.create(nil, record.struct_mt)
ffi.load_fields(path_data_point, { { 'x', ti.double }, { 'y', ti.double } })
cairo._union = rawget(cairo, '_union') or {}
cairo._union.PathData = component.create(nil, record.union_mt, 'cairo.PathData')

-- Populate methods into records.
for _, info in ipairs {
   {  'Rectangle',
      fields = {
	 { 'x', ti.double }, { 'y', ti.double },
	 { 'width', ti.double }, { 'height', ti.double },
      },
   },

   {  'RectangleList',
      fields = {
	 { 'status', cairo.Status },
	 { 'rectangles', cairo.Rectangle, ptr = true },
	 { 'num_rectangles', ti.int },
      },
   },

   {  'RectangleInt',
      fields = {
	 { 'x', ti.int }, { 'y', ti.int },
	 { 'width', ti.int }, { 'height', ti.int },
      },
   },

   {  'Matrix',
      fields = {
	 { 'xx', ti.double }, { 'yx', ti.double },
	 { 'xy', ti.double }, { 'yy', ti.double },
	 { 'x0', ti.double }, { 'y0', ti.double },
      },
      methods = {
	 init = { ti.double, ti.double, ti.double,
		  ti.double, ti.double, ti.double },
	 init_identity = {},
	 init_translate = { ti.double, ti.double },
	 init_scale = { ti.double, ti.double },
	 init_rotate = { ti.double },
	 translate = { ti.double, ti.double },
	 scale = { ti.double, ti.double },
	 rotate = { ti.double },
	 invert = { ret = cairo.Status },
	 multiply = { cairo.Matrix, cairo.Matrix },
	 transform_distance = { { ti.double, dir = 'inout' },
				{ ti.double, dir = 'inout' } },
	 transform_point = { { ti.double, dir = 'inout' },
			     { ti.double, dir = 'inout' } },
      },
   },

   {  'PathData',
      fields = {
	 { 'header', path_data_header },
	 { 'point', path_data_point },
      },
   },

   {  'Path',
      fields = {
	 { 'status', cairo.Status },
	 { 'data', cairo.PathData, ptr = true },
	 { 'num_data', ti.int },
      },

      methods = {
	 extents = { { ti.double, dir = 'out' }, { ti.double, dir = 'out' },
		     { ti.double, dir = 'out' }, { ti.double, dir = 'out' } },
      },
   },

   {  'Context',
      methods = {
	 create = { static = true, ret = { cairo.Context, xfer = true },
		    cairo.Surface },
	 status = { ret = cairo.Status },
	 save = {},
	 restore = {},
	 get_target = { ret = cairo.Surface},
	 push_group = {},
	 push_group_with_content = { cairo.Content },
	 pop_group = {},
	 pop_group_to_source = {},
	 get_group_target = { ret = cairo.Surface },
	 set_source_rgb = { ti.double, ti.double, ti.double },
	 set_source_rgba = { ti.double, ti.double, ti.double, ti.double },
	 set_source = { cairo.Pattern },
	 set_source_surface = { cairo.Surface, ti.double, ti.double },
	 get_source = { ret = cairo.Pattern },
	 set_antialias = { cairo.Antialias },
	 get_antialias = { ret = cairo.Antialias },
	 get_dash_count = { ret = ti.int },
	 set_fill_rule = { cairo.FillRule },
	 get_fill_rule = { ret = cairo.FillRule },
	 set_line_cap = { cairo.LineCap },
	 get_line_cap = { ret = cairo.LineCap },
	 set_line_join = { cairo.LineJoin },
	 get_line_join = { ret = cairo.LineJoin },
	 set_line_width = { ti.double },
	 get_line_width = { ret = ti.double },
	 set_miter_limit = { ti.double },
	 get_miter_limit = { ret = ti.double },
	 set_operator = { cairo.Operator },
	 get_operator = { ret = cairo.Operator },
	 set_tolerance = { ti.double },
	 get_tolerance = { ret = ti.double },
	 clip = {},
	 clip_preserve = {},
	 clip_extents = { { ti.double, dir = 'out' },
			  { ti.double, dir = 'out' },
			  { ti.double, dir = 'out' },
			  { ti.double, dir = 'out' } },
	 in_clip = { ret = ti.boolean },
	 reset_clip = {},
	 copy_clip_rectangle_list = {
	    ret = { cairo.RectangleList, xfer = true } },
	 fill = {},
	 fill_preserve = {},
	 fill_extents = { { ti.double, dir = 'out' },
			  { ti.double, dir = 'out' },
			  { ti.double, dir = 'out' },
			  { ti.double, dir = 'out' } },
	 in_fill = { ti.double, ti.double },
	 mask = { cairo.Pattern },
	 mask_surface = { cairo.Pattern, ti.double, ti.double },
	 paint = {},
	 paint_with_alpha = { ti.double },
	 stroke = {},
	 stroke_preserve = {},
	 stroke_extents = { { ti.double, dir = 'out' },
			    { ti.double, dir = 'out' },
			    { ti.double, dir = 'out' },
			    { ti.double, dir = 'out' } },
	 in_stroke = { ti.double, ti.double },
	 copy_page = {},
	 show_page = {},

	 copy_path = { ret = { cairo.Path, xfer = true } },
	 copy_path_flat = { ret = { cairo.Path, xfer = true } },
	 append_path = { cairo.Path },
	 has_current_point = { ret = ti.boolean },
	 get_current_point = { { ti.double, dir = 'out' },
			       { ti.double, dir = 'out' } },
	 new_path = {},
	 new_sub_path = {},
	 close_path = {},
	 arc = { ti.double, ti.double, ti.double, ti.double, ti.double },
	 arc_negative = { ti.double, ti.double, ti.double,
			  ti.double, ti.double },
	 curve_to = { ti.double, ti.double, ti.double,
		      ti.double, ti.double, ti.double },
	 line_to = { ti.double, ti.double },
	 move_to = { ti.double, ti.double },
	 rectangle = { ti.double, ti.double, ti.double, ti.double },
	 -- glyph_path,
	 text_path = { ti.utf8 },
	 rel_curve_to = { ti.double, ti.double, ti.double,
			  ti.double, ti.double, ti.double },
	 rel_line_to = { ti.double, ti.double },
	 rel_move_to = { ti.double, ti.double },
	 path_extents = { { ti.double, dir = 'out' },
			  { ti.double, dir = 'out' },
			  { ti.double, dir = 'out' },
			  { ti.double, dir = 'out' } },

	 translate = { ti.double, ti.double },
	 scale = { ti.double, ti.double },
	 rotate = { ti.double },
	 transform = { cairo.Matrix },
	 set_matrix = { cairo.Matrix },
	 get_matrix = { cairo.Matrix },
	 identity_matrix = {},
	 user_to_device = { { ti.double, dir = 'inout' },
			    { ti.double, dir = 'inout' } },
	 user_to_device_distance = { { ti.double, dir = 'inout' },
				     { ti.double, dir = 'inout' } },
	 device_to_user = { { ti.double, dir = 'inout' },
			    { ti.double, dir = 'inout' } },
	 device_to_user_distance = { { ti.double, dir = 'inout' },
				     { ti.double, dir = 'inout' } },

	 select_font_face = { ti.utf8, cairo.FontSlant, cairo.FontWeight },
	 set_font_size = { ti.double },
	 set_font_matrix = { cairo.Matrix },
	 get_font_matrix = { cairo.Matrix },
	 set_font_options = { cairo.FontOptions },
	 get_font_options = { cairo.FontOptions },
	 set_font_face = { cairo.FontFace },
	 get_font_face = { ret = cairo.FontFace },
	 set_scaled_font = { cairo.ScaledFont },
	 get_scaled_font = { ret = cairo.ScaledFont },
	 show_text = { ti.utf8 },
	 -- show_glyphs, show_text_glyphs
	 font_extents = { cairo.FontExtents },
	 text_extents = { ti.utf8, cairo.TextExtents },
	 -- glyph extents
      },

      properties = {
	 'status', 'target', 'source', 'antialias', 'fill_rule', 'line_cap',
	 'line_join', 'line_width', 'miter_limit', 'operator', 'tolerance',
	 'font_size', 'font_face', 'scaled_font',
      },
   },

   {  'Pattern',
      methods = {
	 add_color_stop_rgb = { ti.double, ti.double, ti.double, ti.double },
	 add_color_stop_rgba = { ti.double, ti.double, ti.double,
				 ti.double, ti.double },
	 get_color_stop_count = { ret = cairo.Status, { ti.int, dir = 'out' } },
	 get_color_stop_rgba = { ret = cairo.Status, ti.int,
				 { ti.double, dir = 'out' },
				 { ti.double, dir = 'out' },
				 { ti.double, dir = 'out' },
				 { ti.double, dir = 'out' },
				 { ti.double, dir = 'out' } },
	 create_rgb = { static = true, ret = { cairo.Pattern, xfer = true },
			ti.double, ti.double, ti.double },
	 create_rgba = { static = true, ret = { cairo.Pattern, xfer = true },
			 ti.double, ti.double, ti.double, ti.double },
	 get_rgba = { ret = cairo.Status, { ti.double, dir = 'out' },
		      { ti.double, dir = 'out' }, { ti.double, dir = 'out' } },
	 create_for_surface = { static = true,
				ret = { cairo.Pattern, xfer = true },
				cairo.Surface },
	 get_surface = { ret = cairo.Status, { cairo.Surface, dir = 'out' } },
	 create_linear = { static = true, ret = { cairo.Pattern, xfer = true },
			   ti.double, ti.double, ti.double, ti.double },
	 get_linear_points = { ret = cairo.Status, ti.int,
			       { ti.double, dir = 'out' },
			       { ti.double, dir = 'out' },
			       { ti.double, dir = 'out' },
			       { ti.double, dir = 'out' } },
	 create_radial = { static = true, ret = { cairo.Pattern, xfer = true },
			   ti.double, ti.double, ti.double, ti.double,
			   ti.double, ti.double },
	 get_radial_circles = { ret = cairo.Status, ti.int,
				{ ti.double, dir = 'out' },
				{ ti.double, dir = 'out' },
				{ ti.double, dir = 'out' },
				{ ti.double, dir = 'out' },
				{ ti.double, dir = 'out' },
				{ ti.double, dir = 'out' } },
	 status = { ret = cairo.Status },
	 set_extend = { cairo.Extend },
	 get_extend = { ret = cairo.Extend },
	 set_filter = { cairo.Filter },
	 get_filter = { ret = cairo.Filter },
	 set_matrix = { cairo.Matrix },
	 get_matrix = { cairo.Matrix },
	 get_type = { ret = cairo.PatternType },
      },
      properties = { 'status', 'extend', 'filter', 'type' },
   },

   {  'Device',
      methods = {
	 status = { ret = cairo.Status },
	 finish = {},
	 flush = {},
	 get_type = { ret = cairo.DeviceType },
	 acquire = { ret = cairo.Status },
	 release = {},
      },
      properties = { 'status' },
   },

   {  'Format',
      methods = {
	 stride_for_width = { ret = ti.int, cairo.Format },
      },
   },

   {  'Surface',
      methods = {
	 create_similar = { ret = { cairo.Surface, xfer = true },
			    cairo.Content, ti.int, ti.int },
	 create_for_rectangle = { ret = { cairo.Surface, xfer = true },
				  ti.double, ti.double, ti.double, ti.double },
	 status = { ret = cairo.Status },
	 finish = {},
	 flush = {},
	 get_device = { ret = cairo.Device },
	 get_font_options = { cairo.FontOptions },
	 get_content = { ret = cairo.Content },
	 mark_dirty = {},
	 mark_dirty_rectangle = { ti.int, ti.int, ti.int, ti.int },
	 set_device_offset = { ti.double, ti.double },
	 get_device_offset = { { ti.double, dir = 'out' },
			       { ti.double, dir = 'out' } },
	 set_fallback_resolution = { ti.double, ti.double },
	 get_fallback_resolution = { { ti.double, dir = 'out' },
				     { ti.double, dir = 'out' } },
	 get_type = { ret = cairo.SurfaceType },
	 copy_page = {},
	 show_page = {},
	 has_show_text_glyphs = { ret = ti.boolean },
	 -- set_mime_data, get_mime_data
	 write_to_png = { ret = cairo.Status, ti.filename },
      },

      properties = { 'status', 'device', 'content', 'type' },
   },

   {  'ImageSurface', parent = cairo.Surface,
      methods = {
	 create = { static = true, ret = { cairo.Surface, xfer = true },
		    cairo.Format, ti.int, ti.int },
	 create_for_data = { static = true,
			     ret = { cairo.Surface, xfer = true },
			     ti.ptr, cairo.Format, ti.int, ti.int, ti.int },
	 create_from_png = { static = true,
			     ret = { cairo.Surface, xfer = true },
			     ti.filename },
	 get_data = { ret = ti.ptr },
	 get_format = { ret = cairo.Format },
	 get_width = { ret = ti.int },
	 get_height = { ret = ti.int },
	 get_stride = { ret = ti.int },
      },
      properties = { 'data', 'format', 'width', 'height', 'stride' },
   },

   {  'PdfVersion',
      values = {
	 ['1_4'] = 0,
	 ['1_5'] = 1,
      },
   },

   {  'PdfSurface', parent = cairo.Surface,
      methods = {
	 create = { static = true, ret = { cairo.Surface, xfer = true },
		    ti.filename, ti.double, ti.double },
	 restrict_to_version = { cairo.PdfVersion },
	 set_size = { ti.double, ti.double },
      },
   },

   {  'PsLevel',
      values = {
	 ['2'] = 0,
	 ['3'] = 1,
      },
   },

   {  'PsSurface', parent = cairo.Surface,
      methods = {
	 create = { static = true, ret = { cairo.Surface, xfer = true },
		    ti.double, ti.double },
	 restrict_to_level = { cairo.PsLevel },
	 set_eps = { ti.boolean },
	 get_eps = { ret = ti.boolean },
	 set_size = { ti.double, ti.double },
	 dsc_begin_setup = {},
	 dsc_begin_page_setup = {},
	 dsc_comment = { ti.utf8 },
      },
      properties = { 'eps' },
   },

   {  'RecordingSurface', parent = cairo.Surface,
      methods = {
	 create = { static = true, ret = { cairo.Surface, xfer = true },
		    cairo.Content },
	 ink_extents = {
	    { ti.double, dir = 'out' }, { ti.double, dir = 'out' },
	    { ti.double, dir = 'out' }, { ti.double, dir = 'out' } },
      },
   },

   {  'SvgVersion',
      values = {
	 ['1_1'] = 0,
	 ['1_2'] = 1,
      },
   },

   {  'SvgSurface', parent = cairo.Surface,
      methods = {
	 create = { static = true, ret = { cairo.Surface, xfer = true },
		    ti.filename, ti.double, ti.double },
	 restrict_to_version = { cairo.SvgVersion },
      },
   },

   {  'FontFace',
      methods = {
	 status = { ret = cairo.Status },
	 get_type = { ret = cairo.FontType },
      },
      properties = { 'status', 'type' },
   },

   {  'ToyFontFace', parent = cairo.FontFace,
      methods = {
	 create = { static = true, ret = { cairo.ToyFontFace, xfer = true },
		    cairo.FontSlant, cairo.FontWeight },
	 get_family = { ret = ti.utf8 },
	 get_slant = { ret = cairo.Slant },
	 get_weight = { ret = cairo.Weight },
      },
      properties = { 'family', 'slant', 'weight' },
   },

   {  'FontOptions',
      methods = {
	 create = { static = true, ret = { cairo.FontOptions, xfer = true } },
	 copy = { ret = { cairo.FontOptions, xfer = true } },
	 status = { ret = cairo.Status },
	 merge = { cairo.FontOptions },
	 hash = { ret = ti.ulong },
	 equal = { ret = ti.boolean, cairo.FontOptions },
	 set_antialias = { cairo.Antialias },
	 get_antialias = { ret = cairo.Antialias },
	 set_subpixel_order = { cairo.SubpixelOrder },
	 get_subpixel_order = { ret = cairo.SubpixelOrder },
	 set_hint_style = { cairo.HintStyle },
	 get_hint_style = { ret = cairo.HintStyle },
	 set_hint_metrics = { cairo.HintMetrics },
	 get_hint_metrics = { ret = cairo.HintMetrics },
      },
      properties = { 'status', 'antialias', 'subpixel_order',
		     'hint_style', 'hint_metrics' },
   },

   {  'ScaledFont',
      methods = {
	 create = { static = true, ret = { cairo.ScaledFont, xfer = true },
		    cairo.FontFace, cairo.Matrix, cairo.Matrix,
		    cairo.FontOptions },
	 status = { ret = cairo.Status },
	 extents = { cairo.FontExtents },
	 text_extents = { ti.utf8, cairo.TextExtents },
	 -- glyph_extents, text_to_glyphs
	 get_font_face = { ret = cairo.FontFace },
	 get_font_options = { cairo.FontOptions },
	 get_font_matrix = { cairo.Matrix },
	 get_ctm = { cairo.Matrix },
	 get_scale_matrix = { cairo.Matrix },
	 get_type = { ret = cairo.FontType },
      },
      properties = { 'status', 'font_face' },
   },

   {  'Region',
      methods = {
	 create = { static = true, ret = { cairo.Region, xfer = true } },
	 create_rectangle = { static = true,
			      ret = { cairo.Region, xfer = true },
			      cairo.RectangleInt },
	 copy = { ret = cairo.Region },
	 status = { ret = cairo.Status },
	 get_extents = { cairo.RectangleInt },
	 num_rectangles = { ret = ti.int },
	 get_rectangle = { ti.int, cairo.RectangleInt },
	 is_empty = { ret = ti.boolean },
	 contains_point = { ret = ti.boolean, ti.int, ti.int },
	 contains_rectangle = { ret = cairo.RegionOverlap, cairo.RectangleInt },
	 equal = { ret = ti.boolean, cairo.Region },
	 translate = { ti.int, ti.int },
	 intersect = { ret = cairo.Status, cairo.Region },
	 intersect_rectangle = { ret = cairo.Status, cairo.RectangleInt },
	 subtract = { ret = cairo.Status, cairo.Region },
	 subtract_rectangle = { ret = cairo.Status, cairo.RectangleInt },
	 union = { ret = cairo.Status, cairo.Region },
	 union_rectangle = { ret = cairo.Status, cairo.RectangleInt },
	 xor = { ret = cairo.Status, cairo.Region },
	 xor_rectangle = { ret = cairo.Status, cairo.RectangleInt },
      },
      properties = { 'status', 'extents', },
   },
} do
   local name = info[1]
   local obj = assert(cairo[name])
   obj._parent = info.parent
   if info.methods then
      -- Go through description of the methods and create functions
      -- from them.
      obj._method = {}
      local prefix = 'cairo_'
      if name ~= 'Context' then
	 prefix = prefix .. name:gsub('([%l%d])([%u])', '%1_%2'):lower() .. '_'
      end
      local self_arg = { obj }
      for method_name, method_info in pairs(info.methods) do
	 method_info.name = 'cairo.' .. name .. '.' .. method_name
	 method_info.addr = cairo._module[
	    prefix .. (method_info.cname or method_name)]
	 if not method_info.static then
	    table.insert(method_info, 1, self_arg)
	 end
	 method_info.ret = method_info.ret or ti.void
	 obj._method[method_name] = core.callable.new(method_info)
      end
   end
   if info.values then
      -- Fill in addition enum/bitflag values.
      for n, v in pairs(info.values) do
	 obj[n] = v
      end
   end
   if info.properties then
      -- Aggregate getters/setters into pseudoproperties implemented
      -- as attributes.
      obj._attribute = {}
      for _, attr in pairs(info.properties) do
	 obj._attribute[attr] = {
	    get = obj._method['get_' .. attr] or obj._method[attr],
	    set = obj._method['set_' .. attr],
	 }
      end
   end
   if info.fields then
      -- Load record fields definition
      ffi.load_fields(obj, info.fields)
   end
end

-- Map all 'create' methods to constructors.
for _, struct in pairs(cairo._struct) do
   local create = struct._method and struct._method.create
   if create then
      function struct._new(typetable, ...)
	 return create(...)
      end
   end
end

-- Teach non-boxed structs how to destroy itself.
cairo.RectangleList._free = cairo._module.cairo_rectangle_list_destroy
cairo.Path._free = cairo._module.cairo_path_destroy
cairo.FontOptions._free = cairo._module.cairo_font_options_destroy

-- Add Matrix creation routines.
for _, name in pairs { 'identity', 'scale', 'rotate', 'translate' } do
   local init = cairo.Matrix._method['init_' .. name]
   cairo.Matrix._method['create_' .. name] = function(...)
      local matrix = core.record.new(cairo.Matrix)
      init(matrix, ...)
      return matrix
   end
end

-- FontOptions can be created only by 'create' method.
function cairo.FontOptions._method:_new(props)
   local font_options = self.create()
   for k, v in pairs(props or {}) do
      font_options[k] = v
   end
   return font_options
end

-- Fix all 'get_xxx' methods using caller-alloc attribute, which is
-- not supported by ffi.  Emulate it 'by-hand'.
for _, info in pairs {
   { cairo.Context, 'matrix', cairo.Matrix },
   { cairo.Context, 'font_matrix', cairo.Matrix },
   { cairo.Context, 'font_options', cairo.FontOptions },
   { cairo.Pattern, 'matrix', cairo.Matrix },
   { cairo.Surface, 'font_options', cairo.FontOptions },
   { cairo.ScaledFont, 'font_matrix', cairo.Matrix },
   { cairo.ScaledFont, 'ctm', cairo.Matrix },
   { cairo.ScaledFont, 'scale_matrix', cairo.Matrix },
   { cairo.ScaledFont, 'font_options', cairo.FontOptions },
} do
   local getter_name = 'get_' ..info[2]
   local raw_getter = assert(info[1]._method[getter_name])
   info[1]._method[getter_name] = function(self)
      local ret = info[3]()
      raw_getter(self, ret)
      return ret
   end
   info[1]._attribute[info[2]] = {
      get = info[1][getter_name],
      set = info[1]['set_' .. info[2]],
   }
end

-- Choose correct 'subclass' of surface on attaching to surface instances.
local surface_type_map = {
   IMAGE = cairo.ImageSurface,
   PDF = cairo.PdfSurface,
   PS = cairo.PsSurface,
   SVG = cairo.SvgSurface,
   RECORDING = cairo.RecordingSurface,
}
function cairo.Surface:_attach(surface)
   local type = cairo.Surface._method.get_type(surface)
   local repotype = surface_type_map[type]
   if repotype then
      core.record.set(surface, repotype)
   end
end

-- Implementation of Context.dash operations.  Since ffi does not
-- support arrays of doubles, we cheat here and use array of structs
-- containing only single 'double' field.
local wrapped_double = component.create(nil, record.struct_mt)
ffi.load_fields(wrapped_double, { { 'v', ti.double } })
local raw_set_dash = core.callable.new {
   addr = cairo._module.cairo_set_dash, ret = ti.void,
   cairo.Context, wrapped_double, ti.int, ti.double }
local raw_get_dash = core.callable.new {
   addr = cairo._module.cairo_get_dash, ret = ti.void,
   cairo.Context, wrapped_double, { ti.double, dir = 'out' } }
function cairo.Context:set_dash(dashes, offset)
   local count, array = 0
   if dashes and #dashes > 0 then
      -- Convert 'dashes' array into the native array of wrapped_double
      -- records.
      count = #dashes
      array = core.record.new(wrapped_double, nil, count)
      for i = 1, count do
	 core.record.fromarray(array, i - 1).v = dashes[i]
      end
   end
   raw_set_dash(self, array, count, offset)
end

function cairo.Context:get_dash()
   local dashes, offset = {}, 0
   local count = self:get_dash_count()
   if count > 0 then
      -- Prepare native array of wrapped doubles of specified size.
      local array = core.record.new(wrapped_double, nil, count)

      -- Get the dashes.
      offset = raw_get_dash(self, array)

      -- Convert output to the table.
      for i = 1, count do
	 dashes[i] = core.record.fromarray(array, i - 1).v
      end
   end
   return dashes, offset
end

-- Implementation of iteration protocol over the cairo.Path
function cairo.Path:pairs()
   local index = 0
   return function()
      -- Bounds check, and get appropriate header PathData element.
      if index >= self.num_data then return nil end
      local path_data = core.record.fromarray(self.data, index)
      local type, length = path_data.header.type, path_data.header.length

      -- Create 'points' table.
      local points = {}
      if type ~= 'CLOSE_PATH' then
	 points[1] = core.record.fromarray(self.data, index + 1).point
	 if type == 'CURVE_TO' then
	    points[2] = core.record.fromarray(self.data, index + 2).point
	    points[3] = core.record.fromarray(self.data, index + 3).point
	 end
      end

      -- Skip this logical item.
      index = index + length
      return type, points
   end
end
