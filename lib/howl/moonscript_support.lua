moonscript = require('moonscript')
moonscript.errors = require "moonscript.errors"
moon = require('moon')

lua_loadfile = loadfile

loadfile = function(filename, mode, env)
  filename = tostring(filename)
  if (filename:match('%.moon$')) then
    return moonscript.loadfile(filename)
  else
    return lua_loadfile(filename, mode, env)
  end
end

local function error_rewriter(err)
  if not err:match('%.moon') then return err end
  local trace = debug.traceback("", 2)
  trace = trace:match('%s*(.+)%s*$')
  local rewritten = moonscript.errors.rewrite_traceback(trace, err)
  return rewritten or err
end

pcall = function(f, ...)
  return xpcall(f, error_rewriter, ...)
end
