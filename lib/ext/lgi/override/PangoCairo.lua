------------------------------------------------------------------------------
--
--  LGI PangoCairo override module.
--
--  Copyright (c) 2012 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local pairs = pairs
local lgi = require 'lgi'
local PangoCairo = lgi.PangoCairo
local cairo = lgi.cairo
local Pango = lgi.Pango

-- Make assorted PangoCairo global methods taking cairo.Context as first
-- argument methods of the cairo.Context (where they logically belong).
for _, name in pairs {
   'update_context', 'update_layout',
   'show_glyph_string', 'show_glyph_item', 'show_layout_line', 'show_layout',
   'show_error_underline',
   'glyph_string_path', 'layout_line_path', 'layout_path',
   'error_underline_path',
} do
   cairo.Context._method[name] = PangoCairo[name]
end
Pango.Layout._method.create = PangoCairo.create_layout

-- Extend Pango.Context with additional methods and attributes coming from
-- PangoCairo package.
Pango.Context._method.create = PangoCairo.context_create
for _, name in pairs {
   'get_font_options', 'set_font_options', 'get_resolution', 'set_resolution',
   'set_shape_renderer' } do
   Pango.Context._method[name] = PangoCairo['context_' .. name]
end
for _, name in pairs { 'font_options', 'resolution', 'shape_renderer' } do
   Pango.Context._attribute[name] = {
      get = Pango.Context['get_' .. name] or Pango.Context[name],
      set = Pango.Context['set_' .. name],
   }
end
