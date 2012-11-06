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
        if mod:match('module.*not found') then
          mod = lazily_loaded_module(req_name)
        else
          error(mod)
        end
      end

      t[key] = mod
      return mod
    end})
end

--package.path = ''
set_package_path('lib', 'lib/ext', 'lib/ext/moonscript')
package.cpath = ''

require 'lunar.moonscript_support'

-- set up globals (lpeg/lfs already setup from C)
lgi = require('lgi')
lunar = lazily_loaded_module('lunar')
moon = require('moon')
require('lunar.globals')

lunar.app = lunar.Application(lunar.fs.File(app_root), argv)
_G.log = require('lunar.log')

if os.getenv('BUSTED') then
  local support = assert(loadfile(app_root .. '/spec/support/spec_helper.moon'))
  support()
  local busted = assert(loadfile(argv[2]))
  arg = {table.unpack(argv, 3, #argv)}
  busted()
else
  lunar.app:run()
end
