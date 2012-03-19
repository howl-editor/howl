local ffi = require("ffi")
ffi.cdef[[
void * _ui_window_new();
void * _ui_view_new(void *window);
]]
window = ffi.C._ui_window_new()
view = ffi.C._ui_view_new(window)
