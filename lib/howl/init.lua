-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

local app_root, argv = ...
io.stdout:setvbuf('line')

local help = [=[
Usage: howl [options] [<file> [, <file>, ..]]

Where options can be any of:
  --reuse       Opens any named files in an existing instance of Howl, if present
  --compile     Compiles the given files to bytecode
  --run         Loads and runs the specified file from within Howl
  -h, --help    This help
]=]

local function parse_args(argv)
  local options = {
    ['-h'] = 'help',
    ['--help'] = 'help',
    ['--reuse'] = 'reuse',
    ['--compile'] = 'compile',
    ['--run'] = 'run',
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
    end
  })
end

local function bytecode_loader()
  local path = package.path:gsub('.lua', '.bc')
  local bases = {}
  for base in path:gmatch('[^;]+') do
    table.insert(bases, #bases + 1, base)
  end

  return function(name)
    name = name:gsub('%.', '/')
    for i = 1, #bases do
      local target = bases[i]:gsub('?', name)
      local f = loadfile(target)
      if f then return f end
    end
    return nil
  end
end

local function compile(args)
  for i = 2, #args do
    file = args[i]
    local target = file:gsub('%.%w+$', '.bc')
    print('Compiling ' .. file)
    local func = assert(loadfile(file))
    local bytecode = string.dump(func, false)
    local file = assert(io.open(target, 'w'))
    assert(file:write(bytecode))
    file:close()
  end
end

local function main(args)
  set_package_path('lib', 'lib/ext', 'lib/ext/moonscript')
  require 'howl.moonscript_support'
  table.insert(package.loaders, 2, bytecode_loader())

  howl = auto_module('howl')
  require('howl.globals')
  _G.log = require('howl.log')
  local args = parse_args(argv)

  if args.compile then
    compile(args)
  else
    local callbacks = require 'ljglibs.callbacks'
    callbacks.configure({
      dispatch_in_coroutine = true,
      on_error = _G.log.error
    })

    howl.app = howl.Application(howl.io.File(app_root), args)
    assert(jit.status(), "JIT is inadvertently switched off")

    if os.getenv('BUSTED') then
      local busted = assert(loadfile(argv[2]))
      arg = {table.unpack(argv, 3, #argv)}
      local support = assert(loadfile(app_root .. '/spec/support/spec_helper.moon'))
      support()
      busted()
    elseif args.run then
      loadfile(args[2])(table.unpack(args, 3))
    else
      howl.app:run()
    end
  end
end

local status, err = pcall(main, args)
if not status then
  print(err)
  error(err)
end
