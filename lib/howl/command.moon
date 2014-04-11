-- Copyright 2012-2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import inputs, config from howl
import Matcher from howl.util

append = table.insert

commands = {}
accessible_names = {}
command_history = {}

resolve_command = (name) ->
  def = commands[name]
  def = commands[def.alias_for] if def and def.alias_for -- alias
  def

parse_cmd = (text) ->
  cmd_start, cmd_end, cmd, rest = text\find '^%s*([^%s]+)%s+(.*)$'
  return resolve_command(cmd), cmd, rest if cmd
  return nil, nil, text

load_input = (input, text) ->
  return nil if not input
  if type(input) == 'string'
    factory = inputs[input]
    if not factory then error "Could not find input for `#{input}`"
    input = factory

  input text

append_history = (command, text) ->
  last_cmd = command_history[#command_history]
  if last_cmd and last_cmd.command == command and last_cmd.text == text
    return
  append command_history, { :command, :text}

get_historical_cmd = (index) ->
  unless tonumber(index)
    return nil
  return command_history[#command_history - tonumber(index) + 1]

class State
  new: =>
    @inputs = {}
    @arguments = {}

  update: (text, readline) =>
    if not @cmd
      @cmd, name, text = parse_cmd text
      return if not @cmd

      readline.prompt ..= name .. ' '
      readline.text = text or ''
      @input = load_input @cmd.input, readline.text

    @_dispatch 'update', text, readline

  complete: (text, readline, completion_type) =>
    @last_completed_text = text
    @_dispatch 'complete', text, readline, completion_type
  on_completed: (item, readline) => @_dispatch 'on_completed', item, readline
  close_on_cancel: (readline) => @_dispatch 'close_on_cancel', readline
  go_back: (readline) => @_dispatch 'go_back', readline
  on_cancelled: (readline) => @_dispatch 'on_cancelled', readline

  should_complete: (readline) =>
    return @_dispatch('should_complete', readline) if @input
    config.complete == 'always'

  on_selection_changed: (item, readline) =>
    @_dispatch 'on_selection_changed', item, readline

  on_submit: (text, readline) =>
    if not @cmd and resolve_command text
      @update text .. ' ', readline
      return false if @input
    elseif not @cmd
      past_cmd = get_historical_cmd(text)
      if past_cmd
        @update past_cmd.command .. ' ' .. past_cmd.text, readline
        return false

    return false unless @cmd

    if @cmd
      append_history @cmd.name, @last_completed_text

    if @input
      input_says = @_dispatch 'on_submit', text, readline
      return input_says if input_says != nil

      not readline.text.is_blank

  _dispatch: (handler, ...) =>
    if @input and @input[handler]
      return @input[handler] @input, ...

    nil

  submit: (value) =>
    cmd = @cmd or resolve_command value
    return false if not cmd

    values = { value }
    values = { @input\value_for(value) } if @input and @input.value_for
    cmd table.unpack values
    true

accessible_name = (name) ->
  name\lower!\gsub '[%s%p]+', '_'

parse_inputs = (inputs = {}) ->
  iputs = {}

  for i = 1, #inputs
    input = inputs[i]
    wildcard_input = type(input) == 'string' and input\match('^%*(.+)$')

    if wildcard_input
      error('Wildcard input only allowed as last input') if i != #inputs
      input = wildcard_input

    append iputs, factory: input

  iputs

register = (spec) ->
  for field in *{'name', 'description', 'handler'}
    error 'Missing field for command: "' .. field .. '"' if not spec[field]

  c = setmetatable moon.copy(spec), __call: (...) => spec.handler ...
  c.inputs = parse_inputs spec.inputs
  c.input or= spec.inputs and spec.inputs[1]
  commands[spec.name] = c
  sane_name = accessible_name spec.name
  accessible_names[sane_name] = c if sane_name != spec.name

unregister = (name) ->
  cmd = commands[name]
  return if not cmd
  commands[name] = nil

  aliases = {}
  for cmd_name, def in pairs commands
    append aliases, cmd_name if def.alias_for == name

  commands[alias] = nil for alias in *aliases
  sane_name = accessible_name name
  accessible_names[sane_name] = nil if sane_name != name

alias = (target, name, opts = {}) ->
  error 'Target ' .. target .. 'does not exist' if not commands[target]
  def = moon.copy opts
  def.alias_for = target
  commands[name] = def

get = (name) -> commands[name]

names = -> [name for name in pairs commands]

command_bindings = ->
  c_bindings = {}

  for map in *howl.bindings.keymaps
    for m in *{ map, map['editor'] or {} }
      c_bindings[cmd] = binding for binding, cmd in pairs m when type(cmd) == 'string'

  c_bindings

history_completer = ->
  completion_options =
    list:
      headers: { '#', 'Command', 'Text'},
      column_styles: { 'comment', 'keyword', 'string' }
    select_last: true
  items = {}
  for i = 1, #command_history
    past_cmd = command_history[i]
    append items, {tostring(#command_history - i + 1), past_cmd.command, past_cmd.text }

  matcher = Matcher items, preserve_order: true
  (text) -> matcher(text), completion_options

command_completer = ->
  completion_options = list: {
    headers: { 'Command', 'Key binding', 'Description' }
    column_styles: { 'string', 'keyword', 'comment' }
  }
  cmd_names = names!
  bindings = command_bindings!

  table.sort cmd_names
  items = {}
  for name in *cmd_names
    def = commands[name]
    desc = def.description
    if def.alias_for
      desc = "(Alias for #{def.alias_for})"
      desc = "[deprecated] #{desc}" if def.deprecated
    binding = bindings[name] or ''
    append items, { name, binding, desc }

  matcher = Matcher items
  (text) -> matcher(text), completion_options

direct_dispatch = (cmd_string) ->
  return false if not cmd_string or cmd_string.is_blank
  cmd, cmd_name, text = parse_cmd cmd_string
  cmd or= resolve_command cmd_string
  return false unless cmd
  input = load_input cmd.input, text
  return false if input
  cmd!
  true

run = (cmd_string = nil) ->
  return if direct_dispatch cmd_string

  cmd_completer = nil
  state = State!

  cmd_input =
    title: 'Command'
    should_complete: (_, readline) -> state\should_complete readline
    close_on_cancel: (_, readline) -> state\close_on_cancel readline
    update: (_, text, readline) -> state\update text, readline
    on_selection_changed: (_, item, readline) -> state\on_selection_changed item, readline
    on_completed: (_, item, readline) -> state\on_completed item, readline
    on_cancelled: (_, readline) -> state\on_cancelled readline
    on_submit: (_, text, readline) -> state\on_submit text, readline
    go_back: (_, readline) -> state\go_back readline

    complete: (_, text, readline, completion_type) ->
      if state.cmd
        return state\complete(text, readline)
      elseif completion_type == 'history'
        cmd_completer = history_completer!
      else
        cmd_completer or= command_completer!
      cmd_completer text

  readline = howl.app.window.readline
  text = cmd_string
  text = "#{cmd_string} " if cmd_string and not cmd_string\contains ' '
  value = readline\read ':', cmd_input, :text
  if value
    state\submit value

return setmetatable { :register, :unregister, :alias, :run, :names, :get }, {
  __index: (key) => commands[key] or accessible_names[key]
}
