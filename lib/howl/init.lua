-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

local ffi = require('ffi')
local app_root, argv = ...
io.stdout:setvbuf('line')

local help = [=[
Usage: howl [options] [<file> [, <file>, ..]]

Where options can be any of:
  --reuse       Opens any named files in an existing instance of Howl, if present
  --compile     Compiles the given files to bytecode
  --lint        Lints the given files
  --run         Loads and runs the specified file from within Howl
  --no-profile  Starts Howl without loading any user profile (settings, etc)
  --spec        Runs the specified Howl spec file(s)
  -h, --help    This help
]=]

local path_separator = jit.os == 'Windows' and '\\' or '/'

local function parse_args(argv)
  local options = {
    ['-h'] = 'help',
    ['--help'] = 'help',
    ['--reuse'] = 'reuse',
    ['--compile'] = 'compile',
    ['--lint'] = 'lint',
    ['--no-profile'] = 'no_profile',
    ['--spec'] = 'spec',
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

  if args.help and not args.spec then
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
  -- base path is system path except the crazy default current directory
  base_path = package.path:gsub('./?.lua;', '')
  package.path = table.concat(paths, ';') .. ';' .. base_path
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
          relative_path = req_name:gsub('%.', path_separator)
          path = table.concat({ app_root, 'lib', relative_path }, path_separator)
          if ffi.C.g_file_test(path, ffi.C.G_FILE_TEST_IS_DIR) ~= 0 then
            mod = auto_module(req_name)
          else
            error(mod, 2)
          end
        else
          error(mod, 2)
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
    local file = assert(io.open(target, 'wb'))
    assert(file:write(bytecode))
    file:close()
  end
end

local function lint(args)
  local root = howl.io.File(app_root)
  lint_config = root:join('lint_config.moon').path
  local moonpick = require("moonpick")
  local errors = 0
  local paths = {}
  local moon_filter = function(f)
    return f.extension ~= 'moon' and not f.is_directory
  end

  for i = 2, #args do
    local path = args[i]
    local file = howl.io.File(path)
    if file.is_directory then
      local sub_files = file:find({filter = moon_filter})
      for j = 1, #sub_files do
        if not sub_files[j].is_directory then
          paths[#paths + 1] = sub_files[j].path
        end
      end
    else
      paths[#paths + 1] = path
    end
  end

  for i = 1, #paths do
    local path = paths[i]
    local res, err = moonpick.lint_file(path, {lint_config = lint_config})
    if res and #res > 0 then
      io.stderr:write(path .. "\n\n")
      io.stderr:write(moonpick.format_inspections(res) .. "\n\n")
      errors = errors + 1
    elseif err then
      io.stderr:write(path .. "\n" .. err.. "\n\n")
      errors = errors + 1
    end
  end

  os.exit(errors > 0 and 1 or 0)
end

local function main(args)
  set_package_path('lib', 'lib/ext', 'lib/ext/moonscript')
  require 'howl.moonscript_support'
  table.insert(package.loaders, 2, bytecode_loader())
  require 'howl.cdefs.fontconfig'
  ffi.C.FcConfigAppFontAddDir(nil, table.concat({app_root, 'fonts'}, path_separator))
  require 'ljglibs.cdefs.glib'

  howl = auto_module('howl')
  require('howl.globals')
  _G.log = require('howl.log')
  local args = parse_args(argv)

  if args.compile then
    compile(args)
  elseif args.lint then
    lint(args)
  else
    -- set up the the GC to be more aggressive, we have a lot
    -- of cdata that needs to be collected
    collectgarbage('setstepmul', 400)
    collectgarbage('setpause', 99)

    howl.app = howl.Application(howl.io.File(app_root), args)
    assert(jit.status(), "JIT is inadvertently switched off")

    if args.spec then
      set_package_path('lib/ext/spec-support')
      package.loaded.lfs = loadfile(app_root .. '/lib/ext/spec-support/howl-lfs-shim.moon')()
      local busted = assert(loadfile(app_root .. '/lib/ext/spec-support/busted/busted_bootstrap'))
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
