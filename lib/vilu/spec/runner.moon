status, telescope = pcall require, 'telescope'
error 'telescope not installed' if not status
export telescope

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

class Runner
  new: (paths) =>
    @paths = paths

  run: =>
    functions = [loadfile(path) for path in *@paths]
    contexts = {}
    for f in *functions
      telescope.load_contexts f, contexts

    results = telescope.run contexts
    print telescope.test_report contexts, results
    print (telescope.summary_report contexts, results)
    print telescope.error_report contexts, results

return Runner
