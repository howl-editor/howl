local app_root, argv = ...

local function set_package_path(...)
  local paths = {}
  for _, path in ipairs({...}) do
    paths[#paths + 1] = app_root .. '/' .. path .. '/?.lua'
    paths[#paths + 1] = app_root .. '/' .. path .. '/?/init.lua'
  end
  package.path = package.path .. ';' .. table.concat(paths, ';')
end

set_package_path('lib/vilu', 'lib/vendor', 'lib/vendor/moonscript')
package.cpath = ''

require('moonscript')
_G.event = require('core.event')

_G.app = require('core.app').new(app_root, argv)
_G.app:run()
