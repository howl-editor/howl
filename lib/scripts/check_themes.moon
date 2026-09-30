-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
--
-- Applies themes and reports the errors in them. Run it via bin/howl-check-themes, which
-- loads the bundles, and with them the bundled themes.
--
-- Arguments are theme names or theme files; with none, all registered themes are checked.

{:config} = howl
{:theme} = howl.ui
{:File} = howl.io

-- Theme errors, Howl's own as well as Gtk's CSS ones, are logged rather than raised.
-- Collect them instead: without a window, logging would also print them.
errors = {}
log.error = (message) -> errors[#errors + 1] = message

available = [name for name in pairs theme.all]
table.sort available

names, seen, unknown = {}, {}, {}
for arg in *{...}
  continue if seen[arg]
  seen[arg] = true
  file = File arg
  if file.exists and not file.is_directory
    theme.register arg, file
    names[#names + 1] = arg
  elseif theme.all[arg]
    names[#names + 1] = arg
  else
    unknown[#unknown + 1] = arg

names = available if #names == 0 and #unknown == 0

check = (name, first) ->
  errors = {}
  ok, err = pcall ->
    config.theme = name
    -- the first one needs applying, and setting config.theme to its current value
    -- doesn't apply it anyway
    theme.apply! if first

  errors[#errors + 1] = err unless ok
  errors

failed = #unknown > 0

for i, name in ipairs names
  theme_errors = check name, i == 1
  if #theme_errors == 0
    print "ok    #{name}"
  else
    failed = true
    print "FAIL  #{name}"
    for e in *theme_errors
      e = tostring(e)\gsub '^Theme error: ', ''
      print '      ' .. e\gsub('\n([^\n])', '\n      %1')

for arg in *unknown
  print "??    #{arg}: no theme or file by that name"

if #unknown > 0
  print "\nAvailable themes: #{table.concat available, ', '}"

os.exit failed and 1 or 0
