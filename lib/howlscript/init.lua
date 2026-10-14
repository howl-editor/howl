-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- Howlscript compiles to Lua. See README.md in this directory for the language.

local lexer = require('howlscript.lexer')
local parser = require('howlscript.parser')
local compiler = require('howlscript.compiler')
local errors = require('howlscript.errors')

local function read_file(path)
  local fh, err = io.open(path, 'rb')
  if not fh then return nil, err end
  local source = fh:read('*a')
  fh:close()
  return source
end

-- Compiles Howlscript source to Lua. Returns the Lua code, or nil and an error
-- message. `opts.chunkname` names the source in error messages, as Lua chunk names
-- do ('@path' or '=name').
local function to_lua(source, opts)
  opts = opts or {}
  local ok, result = xpcall(function()
    return compiler.compile(parser.parse(lexer.lex(source)), source)
  end, function(err)
    if errors.is_compile_error(err) then return err end
    return debug.traceback(err, 2)
  end)

  if ok then return result end
  if errors.is_compile_error(result) then
    return nil, errors.format(result, source, opts.chunkname)
  end
  error('howlscript: internal compiler error: ' .. tostring(result), 0)
end

-- Like Lua's loadstring: returns a function running the source, or nil and an
-- error message. `env`, if given, is set as the function's environment.
local function hs_loadstring(source, chunkname, env)
  chunkname = chunkname or '=(howlscript)'
  local lua, err = to_lua(source, { chunkname = chunkname })
  if not lua then return nil, err end
  local f, lua_err = loadstring(lua, chunkname)
  if not f then
    -- the compiler produced invalid Lua, which is a bug in the compiler
    error('howlscript: internal compiler error: ' .. lua_err, 0)
  end
  if env then setfenv(f, env) end
  return f
end

local function hs_loadfile(path, env)
  path = tostring(path)
  local source, err = read_file(path)
  if not source then return nil, err end
  return hs_loadstring(source, '@' .. path, env)
end

local function hs_dofile(path, ...)
  return assert(hs_loadfile(path))(...)
end

return {
  to_lua = to_lua,
  loadstring = hs_loadstring,
  loadfile = hs_loadfile,
  dofile = hs_dofile,
}
