-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- Loads Howlscript (.howl) files: hooks the global loadfile, and adds a require
-- searcher for the paths in package.howlpath. The compiler is only loaded with the
-- first .howl file. Unlike MoonScript (moonscript_support.lua) there are no tracebacks
-- to rewrite, as the generated Lua keeps every statement on its source line.

local chained_loadfile = loadfile
local howlscript

local function load_howl(path, env)
  howlscript = howlscript or require('howlscript')
  return howlscript.loadfile(path, env)
end

_G.loadfile = function(filename, mode, env)
  filename = tostring(filename)
  if filename:match('%.howl$') then
    return load_howl(filename, env)
  end
  return chained_loadfile(filename, mode, env)
end

local function to_howl_path(lua_path)
  local paths = {}
  for path in lua_path:gmatch('[^;]+') do
    local base = path:match('^(.*)%.lua$')
    if base then paths[#paths + 1] = base .. '.howl' end
  end
  return table.concat(paths, ';')
end

package.howlpath = to_howl_path(package.path)

-- returns the "no file" list when nothing is found, which require adds to its
-- "module 'x' not found" message
local function searcher(name)
  local path, not_found = package.searchpath(name, package.howlpath)
  if not path then return not_found end
  local f, err = load_howl(path)
  if not f then error(err, 0) end
  return f
end

-- right after preload; lib/howl/init.lua puts the .bc searcher before it
table.insert(package.loaders, 2, searcher)
