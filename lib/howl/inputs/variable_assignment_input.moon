-- Copyright 2012-2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import Matcher from howl.util
import config, app from howl
append = table.insert

parse_assignment = (text) ->
  name, val = text\match('%s*(%S+)%s*=%s*(%S.*)%s*')
  return name, val if name
  return text\match('%s*(%S+)%s*=')

stringify = (value, to_s) ->
  return to_s(value) if type(value) != 'table'
  [stringify o, to_s for o in *value]

option_completions = (def) ->
  options = def.options
  options = options! if callable options
  options = stringify options, def.tostring or tostring

  table.sort options, (a, b) ->
    return a < b if type(a) != 'table'
    return a[1] < b[1]

  options

options_list_options = (options, def, text, current_buffer) ->
  selection = nil
  headers = { 'Option' }
  highlight_matches_for = text
  to_s = def.tostring or tostring

  unless text
    cur_val = current_buffer and current_buffer.config[def.name] or config.get def.name
    if cur_val
      cur_val = to_s(cur_val)
      for option in *options
        if option == cur_val or type(option) == 'table' and option[1] == cur_val
          selection = option

  if type(options[1]) == 'table'
    append headers, 'Description'

  return :headers, :selection, :highlight_matches_for

option_caption = (name, current_buffer, def) ->
  to_s = def.tostring or tostring
  mode_val = current_buffer.mode.config and current_buffer.mode.config[name]
  caption = "Global value: #{to_s config[name]}\n"
  caption ..= "For current mode: #{to_s mode_val}\n"
  caption .. "For current buffer: #{to_s current_buffer.config[name]}"

class VariableAssignmentInput
  new: =>
    vars = [{name, def.description} for name, def in pairs config.definitions]
    table.sort vars, (a, b) -> a[1] < b[1]
    @matcher = Matcher vars
    @current_buffer = app.editor.buffer

  should_complete: => true

  complete: (text) =>
    name, val = parse_assignment text
    if name
      def = config.definitions[name]
      unless def
        log.error "Unknown variable #{name}"
        return

      comp_options = {
        title: name
        caption: def.description .. "\n\n" .. option_caption name, @current_buffer, def
      }
      options = def.options

      if not options
        return {}, comp_options

      completions = option_completions def
      comp_options.list = options_list_options completions, def, val, @current_buffer
      matcher = Matcher completions
      return matcher(val or ''), comp_options

    completion_options = title: 'Set variable', list: headers: { 'Variable', 'Description' }
    return self.matcher(text), completion_options

  on_completed: (_, readline) =>
    @name, @value = parse_assignment readline.text
    return true if @value
    readline.text ..= '='
    return false

  on_submit: => @name and @value

  value_for: (text) =>
    name, value = parse_assignment text
    return :name, :value if name
    name: @name, value: @value

howl.inputs.register {
  name: 'variable_assignment',
  description: 'Returns a table, where .name is the name of a variable and .value is the value to set',
  factory: VariableAssignmentInput
}

return VariableAssignmentInput
