local app_root, argv = ...

print(app_root)

for i, val in ipairs(argv) do
  print(val)
end

package.path = app_root .. '/lib/?.lua;' .. package.path
print(package.path)

local ffi = require("ffi")
local C = ffi.C
ffi.cdef[[
void * window_new();
void * text_view_new(void *window);
intptr_t text_view_sci(void *view, int message, intptr_t wParam, intptr_t lParam);
]]
window = C.window_new()
view = C.text_view_new(window)
