--[[-
@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
]]

local _G = _G
local setmetatable = setmetatable
local ffi = require("ffi")
local C = ffi.C
local lgi = require('lgi')
local Gtk = lgi.Gtk
local core = require 'lgi.core'

local app = {}
local _ENV = app
if setfenv then setfenv(1, _ENV) end

ffi.cdef[[
intptr_t sci_send(void *sci, int message, intptr_t wParam, intptr_t lParam);
]]

function app.new(root_dir, args)
  return setmetatable({
    root_directory = root_dir,
    args = args
  }, { __index = app })
end

function app:run()
  local window = Gtk.Window {
    title = 'Vilu zen',
    default_width = 800,
    default_height = 600,
    on_destroy = Gtk.main_quit
  }
  local sx = _G._core.sci.new()
  local widget = core.object.new(sx)
  window:add(widget)
  window:show_all()

--  window = C.window_new('Vilu zen')
--  view = C.view_new()
--  scin = C.sci_new()
--  C.view_add(view, scin, -1)
--  mode_line = C.sci_new()
--  C.sci_input_allowed(mode_line, false)
--  C.view_add(view, mode_line, 20)
--  C.window_add(window, view, -1)
--  status = C.sci_new()
--  C.sci_input_allowed(status, false)
--  C.window_add(window, status, 20)
--
  local scintilla = _G.require('core.scintilla')
  local sci = scintilla.new(sx, C.sci_send)
  sci:set_property('lexer.lpeg.color.theme', 'dark')
--
  if #self.args > 1 then
   f = _G.assert(_G.io.open(self.args[2]))
   contents = f:read('*a')
   f:close()

   dir_f = sci:get_direct_function()
   dir_p = sci:get_direct_pointer()
   sci:private_lexer_call(scintilla.SCI_GETDIRECTFUNCTION, dir_f)
   sci:private_lexer_call(scintilla.SCI_SETDOCPOINTER, dir_p)
   sci:private_lexer_call(scintilla.SCI_SETLEXERLANGUAGE, 'ruby')
   sci:set_text(contents)
   sci:grab_focus()
  end

  lgi.Gtk.main();
end

return app
