local app_root, argv = ...

local function set_package_path(...)
  local paths = {}
  for _, path in ipairs({...}) do
    paths[#paths + 1] = app_root .. '/' .. path .. '/?.lua'
    paths[#paths + 1] = app_root .. '/' .. path .. '/?/init.lua'
  end
  package.path = table.concat(paths, ';') .. ';' .. package.path
end

local function lazily_loaded_module(name)
  return setmetatable(
    {},
    { __index = function (t, key)
      local req_name = name .. '.' .. key:lower()
      local status, mod = pcall(require, req_name)
      if not status then
        if mod:find('not found') then
          mod = lazily_loaded_module(req_name)
        else
          error(mod)
        end
      end

      t[key] = mod
      return mod
    end})
end

package.path = ''
set_package_path('lib', 'lib/ext', 'lib/ext/moonscript')
package.cpath = ''

moonscript = require('moonscript')

-- set up globals (lpeg/lfs already setup from C)
lgi = require('lgi')
vilu = lazily_loaded_module('vilu')
moon = require('moon')

if #argv > 1 and argv[2] == '--spec' then
  set_package_path('lib/ext/telescope')
  vilu.spec.Runner({select(3, unpack(argv))}):run()
else
  vilu.app = vilu.Application(vilu.fs.File(app_root), argv)
  vilu.app:run()
end
