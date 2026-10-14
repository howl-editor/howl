-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- Helpers for the Howlscript specs.

howlscript = require 'howlscript'

-- Strips the first line's indentation from every line, so that sources can be
-- written indented in the specs. A leading line break is dropped.
dedent = (s) ->
  s = s\gsub '^\n', ''
  indent = s\match '^[ \t]*'
  lines = [l\sub(#indent + 1) for l in (s .. '\n')\gmatch '([^\n]*)\n']
  table.concat lines, '\n'

-- The Lua for a source, raising the error if it doesn't compile.
compile = (src) ->
  lua, err = howlscript.to_lua dedent(src), chunkname: '=spec'
  error err, 0 unless lua
  lua

-- The compile error for a source, or nil if it compiles.
compile_error = (src) ->
  _, err = howlscript.to_lua dedent(src), chunkname: '=spec'
  err

-- Runs a source in a fresh environment that falls back on the globals, returning
-- what it returns.
run = (src, env = {}, ...) ->
  setmetatable env, __index: _G unless getmetatable env
  f, err = howlscript.loadstring dedent(src), '=spec', env
  error err, 0 unless f
  f ...

{ :dedent, :compile, :compile_error, :run }
