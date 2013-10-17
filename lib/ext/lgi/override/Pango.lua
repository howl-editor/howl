------------------------------------------------------------------------------
--
--  LGI Pango override module.
--
--  Copyright (c) 2012 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local pairs, rawget = pairs, rawget
local table = require 'table'

local lgi = require 'lgi'
local Pango = lgi.Pango

local core = require 'lgi.core'
local gi = core.gi
local ffi = require 'lgi.ffi'
local ti = ffi.types
local record = require 'lgi.record'
local component = require 'lgi.component'

-- Provide defines which are not present in the GIR
local _ = Pango.SCALE
for name, value in pairs {
   SCALE_XX_SMALL = 1 / (1.2 * 1.2 * 1.2),
   SCALE_X_SMALL = 1 / (1.2 * 1.2),
   SCALE_SMALL = 1 / 1.2,
   SCALE_MEDIUM = 1,
   SCALE_LARGE = 1.2,
   SCALE_X_LARGE = 1.2 * 1.2,
   SCALE_XX_LARGE = 1.2 * 1.2 * 1.2,
} do
   if not Pango[name] then
      Pango._constant[name] = value
   end
end

-- Because of https://bugzilla.gnome.org/show_bug.cgi?id=672133 Pango
-- enums are not gtype based on some platforms.  If we detect non-gtype
-- enum, reload it using ffi and GEnumInfo machinery.
for _, enum in pairs {
   'AttrType', 'Underline', 'BidiType', 'Direction', 'CoverageLevel',
   'Style', 'Variant', 'Weight', 'Stretch', 'FontMask', 'Gravity',
   'GravityHint', 'Alignment', 'WrapMode', 'EllipsizeMode', 'RenderPart',
   'Script', 'TabAlign',
} do
   if not Pango[enum]._gtype then
      local gtype = ffi.load_gtype(
	 core.gi.Pango.resolve,
	 'pango_' .. enum:gsub('([%l%d])([%u])', '%1_%2'):lower()
	 .. '_get_type')
      Pango._enum[enum] = ffi.load_enum(gtype, 'Pango.' .. enum)
   end
end

local pango_layout_set_text = Pango.Layout.set_text
function Pango.Layout._method:set_text(text, len)
   pango_layout_set_text(self, text, len or -1)
end
local pango_layout_set_markup = Pango.Layout.set_markup
function Pango.Layout._method:set_markup(text, len)
   pango_layout_set_markup(self, text, len or -1)
end

-- Pango.Layout:set_attributes() has incorrect transfer-full
-- annotation on its attrs argument.  Workaround for
-- https://github.com/pavouk/lgi/issues/60
if gi.Pango.Layout.methods.set_attributes.args[1].transfer ~= 'none' then
   local _ = Pango.Layout._method.set_attributes
   Pango.Layout._method.set_attributes = core.callable.new {
      addr = core.gi.Pango.resolve.pango_layout_set_attributes,
      name = 'Pango.Layout.set_attributes',
      ret = ti.void,
      gi.Pango.Layout.methods.new.return_type,
      gi.Pango.Layout.methods.set_attributes.args[1].typeinfo,
   }
end

-- Add attributes simulating logically missing properties in Pango classes.
for compound, attrs in pairs {
   [Pango.Layout] = {
      'attributes', 'font_description', 'width', 'height', 'wrap', 'context',
      'is_wrapped', 'ellipsize', 'is_ellipsized', 'indent', 'spacing',
      'justify', 'auto_dir', 'alignment', 'tabs', 'single_paragraph_mode',
      'baseline', 'line_count', 'lines', 'log_attrs', 'character_count',
      'text', 'markup',
   },
   [Pango.Context] = {
      'base_dir', 'base_gravity', 'font_description', 'font_map', 'gravity',
      'gravity_hint', 'language', 'matrix',
   },
   [Pango.FontMetrics] = {
      'ascent', 'descent', 'approximate_char_width', 'approximate_digit_width',
      'underline_thickness', 'underline_position',
      'strikethrough_thinkess', 'strikethrough_position',
   },
} do
   compound._attribute = rawget(compound, '_attribute') or {}
   for _, name in pairs(attrs) do
      if not compound._property or not compound._property[name] then
	 compound._attribute[name] = {
	    get = compound['get_' .. name] or compound[name],
	    set = compound['set_' .. name],
	 }
      end
   end
end

-- Handling of poor-man's OO invented by Pango.Attribute related
-- pseudoclasses.
Pango.Attribute._free = core.gi.Pango.Attribute.methods.destroy
for name, def in pairs {
   language_new = { Pango.Language },
   family_new = { ti.utf8 },
   style_new = { Pango.Style },
   variant_new = { Pango.Variant },
   stretch_new = { Pango.Stretch },
   weight_new = { Pango.Weight },
   size_new = { ti.int },
   size_new_absolute = { ti.int },
   desc_new = { Pango.FontDescription },
   foreground_new = { ti.uint16, ti.uint16, ti.uint16 },
   background_new = { ti.uint16, ti.uint16, ti.uint16 },
   strikethrough_new = { ti.boolean },
   strikethrough_color_new = { ti.uint16, ti.uint16, ti.uint16 },
   underline_new = { Pango.Underline },
   underline_color_new = { ti.uint16, ti.uint16, ti.uint16 },
   shape_new = { Pango.Rectangle, Pango.Rectangle },
   scale_new = { ti.double },
   rise_new = { ti.int },
   letter_spacing_new = { ti.int },
   fallback_new = { ti.boolean },
   gravity_new = { Pango.Gravity },
   gravity_hint_new = { Pango.GravityHint },
} do
   def.addr = core.gi.Pango.resolve['pango_attr_' .. name]
   def.name = 'Pango.Attribute.' .. name
   def.ret = { Pango.Attribute, xfer = true }
   Pango.Attribute._method[name] = core.callable.new(def)
end

-- Adding Pango.Attribute into the Pango.AttrList takes ownership of
-- the record.  Pfft, crappy API, wrap and handle.
for _, name in pairs { 'insert', 'insert_before', 'change' } do
   local raw_method = Pango.AttrList[name]
   Pango.AttrList._method[name] = function(list, attr)
      -- Invoke original method first, then unown the attribute.
      raw_method(list, attr)
      core.record.set(attr, false)
   end
end

-- Pango.Layout:move_cursor_visually() is missing an (out) annotation
-- in older Pango releases.  Work around this limitation by creating
-- custom ffi definition for this method.
if gi.Pango.Layout.methods.move_cursor_visually.args[6].direction ~= 'out' then
   local _ = Pango.Layout.move_cursor_visually
   Pango.Layout._method.move_cursor_visually = core.callable.new {
      addr = core.gi.Pango.resolve.pango_layout_move_cursor_visually,
      name = 'Pango.Layout.move_cursor_visually',
      ret = ti.void,
      gi.Pango.Layout.methods.new.return_type,
      ti.boolean, ti.int, ti.int, ti.int,
      { ti.int, dir = 'out' }, { ti.int, dir = 'out' },
   }
end
