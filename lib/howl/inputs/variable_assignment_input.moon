-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import Matcher from howl.util
import config, app from howl
append = table.insert

parse_assignment = (text) ->
  name, val = text\match('%s*(%S+)%s*=%s*(%S.*)%s*')
  return name, val if name
  return text\match('%s*(%S+)%s*=')

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

options_list_options = (options, def, text, current_buffer) ->
  selection = nil
  headers = { 'Option' }
  highlight_matches_for = text

  unless text
    cur_val = current_buffer and current_buffer.config[def.name] or config.get def.name
    if cur_val
      cur_val = tostring(cur_val)
      for option in *options
        if option == cur_val or type(option) == 'table' and option[1] == cur_val
          selection = option

  if type(options[1]) == 'table'
    append headers, 'Description'

  return :headers, :selection, :highlight_matches_for

option_caption = (name, current_buffer) ->
  caption = "Global value: #{config[name]}\n"
  caption ..= "For current mode: #{current_buffer.mode.config[name]}\n"
  caption .. "For current buffer: #{current_buffer.config[name]}"

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
        caption: def.description .. "\n\n" .. option_caption name, @current_buffer
      }
      options = def.options

      if not options
        return {}, comp_options

      completions = option_completions options
      comp_options.list = options_list_options completions, def, val, @current_buffer
      matcher = Matcher completions
      return matcher(val or ''), comp_options

    completion_options = title: 'Set variable', list: headers: { 'Variable', 'Description' }
    return self.matcher(text), completion_options

  on_completed: (_, readline) =>
    name, val = parse_assignment readline.text
    return true if val
    readline.text ..= '='
    return false

  value_for: (text) =>
    name, value = parse_assignment text
    return :name, :value

howl.inputs.register 'variable_assignment', VariableAssignmentInput
return VariableAssignmentInput
