-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
--
-- Compiles Howlscript to Lua and prints the result. Each statement of the Lua
-- starts on the line it starts on in the Howlscript.
--
-- Normally invoked via bin/howlc; directly it is
--
--   ./src/howl --run lib/scripts/howlscript_to_lua.moon [-e <code>] [<file>|-]...

howlscript = require 'howlscript'

-- NOTE: -h/--help and -v/--version never reach this script - howl's own argument
-- parser (lib/howl/init.lua) intercepts them. bin/howlc handles --help itself.

die = (msg) ->
  io.stderr\write "howlc: #{msg}\n"
  os.exit 1

read_all = (path) ->
  return io.read('*a') or '' if path == '-'
  fh, err = io.open path, 'r'
  die err unless fh
  content = fh\read('*a') or ''
  fh\close!
  content

args = {...}
inputs = {}
i = 1

while i <= #args
  arg = args[i]
  switch arg
    when '-e', '--eval'
      i += 1
      code = args[i]
      die '-e requires an argument' unless code
      inputs[#inputs + 1] = { name: '<snippet>', :code }
    else
      name = arg == '-' and '<stdin>' or arg
      code = read_all arg
      inputs[#inputs + 1] = { :name, :code }
  i += 1

if #inputs == 0
  inputs[1] = { name: '<stdin>', code: io.read('*a') or '' }

status = 0

for idx, input in ipairs inputs
  lua, err = howlscript.to_lua input.code, chunkname: "=#{input.name}"

  if lua
    if #inputs > 1
      io.write '\n' if idx > 1
      io.write "-- >>> #{input.name}\n"

    io.write lua
    io.write '\n' unless lua\match '\n$'
  else
    io.stderr\write "#{err}\n"
    status = 1

os.exit status
