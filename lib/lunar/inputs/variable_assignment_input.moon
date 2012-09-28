import Matcher from lunar.completion
import config from lunar

parse_assignment = (text) ->
  name, val = text\match('%s*([^%s]+)%s*=%s*([^%s]+)')
  return name, val if name
  return text\match('%s*([^%s]+)%s*=')

stringify = (value) ->
  return tostring(value) if type(value) != 'table'
  [stringify o for o in *value]

option_completions = (options) ->
  options = options! if callable options
  options = stringify options

  table.sort options, (a, b) ->
    return a < b if type(a) != 'table'
    return a[1] < b[1]

  options

options_list_options = (options, def) ->
  selection = nil
  headers = { 'Option' }
  caption = def.name .. ': ' .. def.description .. '\n'

  cur_val = config.get def.name
  if cur_val
    cur_val = tostring(cur_val)
    for option in *options
      if option == cur_val or type(option) == 'table' and option[1] == cur_val
        selection = option

  if type(options[1]) == 'table'
    append headers, 'Description'

  return list: :caption, :headers, :selection

class VariableAssignmentInput
  new: (readline) =>
    @readline = readline
    vars = [{name, def.description} for name, def in pairs config.definitions]
    table.sort vars, (a, b) -> a[1] < b[1]
    @matcher = Matcher vars

  should_complete: => true

  complete: (text) =>
    name, val = parse_assignment text
    if name
      def = config.definitions[name]
      options = def and def.options
      return {} if not options
      completions = option_completions options
      list_options = options_list_options completions, def
      matcher = Matcher(completions)
      return matcher(val or ''), list_options

    completion_options = list: headers: { 'Variable', 'Description' }
    return self.matcher(text), completion_options

  on_completed: (text) =>
    name, val = parse_assignment @readline.text
    return true if val
    @readline.text ..= '='
    return false

  value_for: (text) =>
    name, value = parse_assignment text
    return :name, :value

lunar.inputs.register 'variable_assignment', VariableAssignmentInput
return VariableAssignmentInput
