local app_root, argv = ...

local function set_package_path(...)
  local paths = {}
  for _, path in ipairs({...}) do
    paths[#paths + 1] = app_root .. '/' .. path .. '/?.lua'
    paths[#paths + 1] = app_root .. '/' .. path .. '/?/init.lua'
  end
  package.path = package.path .. ';' .. table.concat(paths, ';')
end

set_package_path('lib', 'lib/vilu', 'lib/vendor', 'lib/vendor/moonscript')
package.cpath = ''

require('moonscript')

-- set up globals (lpeg/lfs already setup from C)
event = require('core.event')
lgi = require('lgi')
vilu = {
  fs = require('vilu.fs'),
}

vilu.app = require('core.app').new(vilu.fs.File(app_root), argv)
vilu.app:run()
