local app_root, argv = ...

local help = [=[
Usage: howl [options] [<file> [, <file>, ..]]

Where options can be any of:
  --reuse       Opens any named files in an existing instance of Howl, if present
  -h, --help    This help
]=]

local function parse_args(argv)
  local options = {
    ['-h'] = 'help',
    ['--help'] = 'help',
    ['--reuse'] = 'reuse',
  }
  local args = {}

  for _, arg in ipairs(argv) do
    opt = options[arg]
    if opt then
      args[opt] = true
    else
      args[#args + 1] = arg
    end
  end

  if args.help then
    print(help)
    os.exit(0)
  end

  return args
end

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
      local req_name = name .. '.' .. key:gsub('%l%u', function(match)
        return match:gsub('%u', function(upper) return '_' .. upper:lower() end)
      end):lower()
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

local function main()
  howl.app = howl.Application(howl.fs.File(app_root), parse_args(argv))

  if os.getenv('BUSTED') then
    local support = assert(loadfile(app_root .. '/spec/support/spec_helper.moon'))
    support()
    local busted = assert(loadfile(argv[2]))
    arg = {table.unpack(argv, 3, #argv)}
    busted()
  else
    status, err = pcall(howl.app.run, howl.app)
    if not status then
      print(err)
    end
  end

end

set_package_path('lib', 'lib/ext', 'lib/ext/moonscript')
require 'howl.moonscript_support'
lgi = require('lgi')
howl = auto_module('howl')
require('howl.globals')
local code_cache = require('howl.code_cache')(app_root .. '/lib')
table.insert(package.loaders, 2, code_cache.loader)
_G.log = require('howl.log')

status, err = pcall(main)
if not status then
  print(err)
end

code_cache.save()
