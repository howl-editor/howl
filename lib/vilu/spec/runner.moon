status, telescope = pcall require, 'telescope'
error 'telescope not installed' if not status
export telescope

import parse, compile from moonscript
import File from vilu.fs

format_table = (t) ->
  if t == nil
    'nil'
  else
   '{' .. table.concat(t, ', ') .. '}'

telescope.make_assertion 'table_equal',
  (_, a, b) ->
    "Assert failed: expected " .. format_table(a) .. ' to be equal to ' .. format_table(b),
  (a,b) ->
    return false if type(b) != 'table' or #a != #b
    for k,v in pairs a
      return false if v != b[k]
    true

class Runner
  new: (paths) =>
    @paths = paths

  run: =>
    files = [File(path) for path in *@paths]
    functions = [self.load_spec(file) for file in *files]
    contexts = {}
    for f in *functions
      telescope.load_contexts f, contexts

    results = telescope.run contexts
    print telescope.test_report contexts, results
    print (telescope.summary_report contexts, results)
    print telescope.error_report contexts, results

  load_spec: (file) ->
    if file.extension == 'moon'
      moonscript.loadfile file.path
    else
      loadfile file

return Runner
