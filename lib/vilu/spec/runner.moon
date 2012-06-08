status, telescope = pcall require, 'telescope'
error 'telescope not installed' if not status
export telescope

import File from vilu.fs

format_table = (t) ->
  if t == nil
    'nil'
  else
    t2 = {}
    for k,v in ipairs t
      if type(v) == 'table'
        t2[k] = format_table(v)
      else
        t2[k] = v
    return '{' .. table.concat(t2, ', ') .. '}'

telescope.make_assertion 'table_equal',
  (_, a, b) ->
    "Assert failed: expected `" .. format_table(a) .. '` to be equal to `' .. format_table(b) .. '`',
  (a,b) ->
    return false if type(b) != 'table' or #a != #b
    return format_table(a) == format_table(b)

telescope.make_assertion 'includes',
  (_, table, b) ->
    "Assert failed: expected `" .. format_table(table) .. '` to include `' .. tostring(b) .. '`',
  (t,b) ->
    error 'Not a table', 1 if type(t) != 'table'
    for v in *t do return true if v == b
    return false

export with_tmpfile = (f) ->
  file = File.tmpfile!
  status, err = pcall f, file
  file\delete_all! if file.exists
  error err if not status

export with_tmpdir = (f) ->
  dir = File.tmpdir!
  status, err = pcall f, dir
  dir\delete_all! if dir.exists
  error err if not status

class Runner
  new: (paths) =>
    @paths = [File(path) for path in *paths]

  run: =>
    functions = [loadfile(file) for file in *self\_spec_files!]
    contexts = {}
    for f in *functions
      telescope.load_contexts f, contexts

    results = telescope.run contexts
    print telescope.test_report contexts, results
    print (telescope.summary_report contexts, results)
    print telescope.error_report contexts, results

  _spec_files: =>
    files = {}
    for path in *@paths
      if path.is_directory
        for spec in *path\find name: '_spec%.%a+$'
          table.insert files, spec
      else
        table.insert files, path
    files

return Runner
