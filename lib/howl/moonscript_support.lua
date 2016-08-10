moonscript = require('moonscript')
moonscript.errors = require "moonscript.errors"
moon = require('moon')
local line_tables = require "moonscript.line_tables"

lua_loadfile = loadfile
lua_pcall = pcall

loadfile = function(filename, mode, env)
  filename = tostring(filename)
  if (filename:match('%.moon$')) then
    local status, ret = moonscript.loadfile(filename)
    if not status then
      return nil, filename .. ': ' .. ret
    end
    return status, ret
  else
    return lua_loadfile(filename, mode, env)
  end
end

local function error_rewriter(err)
  if type(err) ~= 'string' then return err end
  if not err:match('%.moon') then return err end
  moon_file = err:match('^%[string "([^"]+%.moon)"%]')
  if not moon_file then return err end

  -- if the file hasn't been compiled yet we do it first for error rewriting to work
  if not line_tables[moon_file] then
    lua_pcall(moonscript.loadfile, moon_file)
  end

  local trace = debug.traceback("", 2)
  trace = trace:match('%s*(.+)%s*$')
  local rewritten = moonscript.errors.rewrite_traceback(trace, err)
  return rewritten or err
end

pcall = function(f, ...)
  return xpcall(f, error_rewriter, ...)
end
