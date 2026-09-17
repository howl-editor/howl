-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
--
-- Compiles MoonScript to Lua and prints the result. Reach for this whenever the
-- semantics of a piece of MoonScript are in doubt - implicit returns, @ scoping,
-- comprehension desugaring - the generated Lua settles it immediately.
--
-- Normally invoked via bin/howl-moonc; directly it is
--
--   ./src/howl --run lib/scripts/to_lua.moon [-e <code>] [<file>|-]...

moonscript = require 'moonscript'

-- NOTE: -h/--help and -v/--version are not handled here and never can be - howl's own
-- argument parser (lib/howl/init.lua) scans every argument and intercepts them before
-- the script runs. bin/howl-moonc handles --help itself.

die = (msg) ->
  io.stderr\write "howl-moonc: #{msg}\n"
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
  -- to_lua returns (code, line_table) or (nil, err); only the code is wanted here,
  -- printing the second value is what leaks a bare "table: 0x..." into the output.
  lua, err = moonscript.to_lua input.code

  if lua
    if #inputs > 1
      io.write '\n' if idx > 1
      io.write "-- >>> #{input.name}\n"

    io.write lua
    io.write '\n' unless lua\match '\n$'
  else
    io.stderr\write "#{input.name}: #{err}\n"
    status = 1

os.exit status
