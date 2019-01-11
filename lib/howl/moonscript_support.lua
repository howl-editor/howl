local moonscript = require('moonscript')
moonscript.errors = require "moonscript.errors"
local line_tables = require "moonscript.line_tables"

local lua_loadfile = loadfile
local lua_pcall = pcall

_G.moon = require('moon')

_G.loadfile = function(filename, mode, env)
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
  local moon_file = err:match('^%[string "([^"]+%.moon)"%]') or err:match('^([^%s]+%.moon)')
  if not moon_file then return err end

  -- if the file hasn't been compiled yet we do it first for error rewriting to work
  if not line_tables[moon_file] then
    lua_pcall(moonscript.loadfile, moon_file)
  end

  local trace = debug.traceback("", 2)
  trace = trace:match('%s*(.+)%s*$')
  local rewritten = moonscript.errors.rewrite_traceback(trace, err)
  if howl.sys.env.HOWL_PRINT_TRACEBACKS then
    print(rewritten)
  end
  howl.log.traceback(rewritten)
  return rewritten or err
end

_G.pcall = function(f, ...)
  local rets = table.pack(xpcall(f, error_rewriter, ...))
  return table.unpack(rets, 1, rets.n)
end
