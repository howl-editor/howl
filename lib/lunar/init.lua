local app_root, argv = ...

local function set_package_path(...)
  local paths = {}
  for _, path in ipairs({...}) do
    paths[#paths + 1] = app_root .. '/' .. path .. '/?.lua'
    paths[#paths + 1] = app_root .. '/' .. path .. '/?/init.lua'
  end
  package.path = table.concat(paths, ';') .. ';' .. package.path
end

local function auto_module(name)
  return setmetatable(
    {},
    { __index = function (t, key)
      local req_name = name .. '.' .. key:lower()
      local status, mod = pcall(require, req_name)
      if not status then
        if mod:match('module.*not found') then
          mod = auto_module(req_name)
        else
          error(mod)
        end
      end

      t[key] = mod
      return mod
    end})
end

set_package_path('lib', 'lib/ext', 'lib/ext/moonscript')

require 'lunar.moonscript_support'
lgi = require('lgi')
lunar = auto_module('lunar')

local code_cache = require('lunar.code_cache')(app_root .. '/lib')
table.insert(package.loaders, 2, code_cache.loader)

require('lunar.globals')
_G.log = require('lunar.log')

lunar.app = lunar.Application(lunar.fs.File(app_root), argv)

if os.getenv('BUSTED') then
  local support = assert(loadfile(app_root .. '/spec/support/spec_helper.moon'))
  support()
  local busted = assert(loadfile(argv[2]))
  arg = {table.unpack(argv, 3, #argv)}
  busted()
else
  lunar.app:run()
end

code_cache.save()
