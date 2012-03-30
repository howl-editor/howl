local app_root, argv = ...

function prepend_app_path(path)
  package.path = app_root .. '/' .. path .. ';' .. package.path
end

prepend_app_path('lib/vilu/?/init.lua')
prepend_app_path('lib/vilu/?.lua')

_G.event = require('core.event')

local ffi = require("ffi")
local C = ffi.C
ffi.cdef[[
void * window_new();
void * text_view_new(void *window);
intptr_t text_view_sci(void *view, int message, intptr_t wParam, intptr_t lParam);
]]
window = C.window_new()
view = C.text_view_new(window)

local scintilla = require('core.scintilla')
function send(message, wParam, lParam)
  return C.text_view_sci(view, message, ffi.cast('intptr_t', wParam), ffi.cast('intptr_t', lParam))
end

sci = scintilla.new(send)
sci:set_property('lexer.lpeg.color.theme', 'dark')

if #argv > 1 then
 f = assert(io.open(argv[2]))
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
