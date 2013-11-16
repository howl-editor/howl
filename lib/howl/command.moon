-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import inputs, config, keymap from howl
import Matcher from howl.util

commands = {}
accessible_names = {}

-- command state
resolve_command = (name) ->
  def = commands[name]
  def = commands[def] if type(def) == 'string' -- alias
  def

parse_cmd = (text) ->
  cmd_start, cmd_end, cmd, rest = text\find '^%s*([^%s]+)%s+(.*)$'
  return resolve_command(cmd), cmd, rest if cmd
  return nil, nil, text

class State
  new: =>
    @inputs = {}
    @arguments = {}

  update: (text, readline) =>
    if not @cmd
      @cmd, name, text = parse_cmd text
      return if not @cmd
      if readline
        readline.prompt ..= name .. ' '
        readline.text = text or ''

    @_parse_arguments text, readline

    -- we always want the next input loaded, since we might be on the next
    -- incomplete argument
    @_ensure_input_loaded #@arguments + 1

  _parse_arguments: (text, readline) =>
    args = [ part for part in text\gmatch '(%S+)%s' ]

    for index, arg in ipairs args
      @_ensure_input_loaded #@arguments + 1
      current_input = @inputs[#@inputs]
      return unless current_input

      if current_input.wildcard
        @arguments[index] = table.concat args, ' ', index
        return

      append @arguments, arg
      readline.prompt ..= arg .. ' ' if readline

  should_complete: (text, readline) =>
    should = @_dispatch 'should_complete', text, readline
    return should != nil and should or config.complete == 'always'

  close_on_cancel: (text, readline) => @_dispatch 'close_on_cancel', text, readline
  complete: (text, readline) => @_dispatch 'complete', text, readline
  on_completed: (item, readline) => @_dispatch 'on_completed', item, readline
  on_submit: (text, readline) => @_dispatch 'on_submit', text, readline
  go_back: (readline) => @_dispatch 'go_back', readline
  on_cancelled: (readline) =>
    for input in *@inputs
      if input.target.on_cancelled
        input.target\on_cancelled readline

  _dispatch: (handler, ...) =>
    current_input = @inputs[#@inputs]
    if current_input and current_input.target[handler]
      return current_input.target[handler] current_input.target, ...
    nil

  submit: (value) =>
    cmd = @cmd or resolve_command value
    return false if not cmd

    if #@arguments >= #cmd.inputs
      values = {}
      for i = 1, #@arguments
        target = @inputs[i].target
        value = @arguments[i]
        value = target\value_for(value) if target.value_for
        append values, value

      cmd table.unpack values
      return true

    return false

  to_string: =>
    return '' if not @cmd
    s = @cmd.name
    if #@arguments > 0
      s ..= ' ' .. table.concat @arguments, ' '
    s .. ' '

  _ensure_input_loaded: (input_index) =>
    input = @inputs[input_index]

    if not input
      return nil if not @cmd.inputs
      input_spec = @cmd.inputs[input_index]
      return nil if not input_spec
      input_factory = input_spec.factory
      if type(input_factory) == 'string'
        factory = inputs[input_factory]
        if not factory then error "Could not find input for `#{input_factory}`"
        input_factory = factory

      target = input_factory!
      input = :target, wildcard: input_spec.wildcard
      table.insert @inputs, input_index, input

    input

-- command interface

accessible_name = (name) ->
  name\lower!\gsub '[%s%p]+', '_'

parse_inputs = (inputs = {}) ->
  iputs = {}

  for i = 1, #inputs
    input = inputs[i]
    wildcard = false
    wildcard_input = type(input) == 'string' and input\match('^%*(.+)$')

    if wildcard_input
      error('Wildcard input only allowed as last input') if i != #inputs
      input = wildcard_input
      wildcard = true

    append iputs, factory: input, :wildcard

  iputs

register = (spec) ->
  for field in *{'name', 'description', 'handler'}
    error 'Missing field for command: "' .. field .. '"' if not spec[field]

  c = setmetatable moon.copy(spec), __call: (...) => spec.handler ...
  c.inputs = parse_inputs spec.inputs
  commands[spec.name] = c
  sane_name = accessible_name spec.name
  accessible_names[sane_name] = c if sane_name != spec.name

unregister = (name) ->
  cmd = commands[name]
  return if not cmd
  commands[name] = nil

  aliases = {}
  for cmd_name, target in pairs commands
    append aliases, cmd_name if target == name

  commands[alias] = nil for alias in *aliases
  sane_name = accessible_name name
  accessible_names[sane_name] = nil if sane_name != name

alias = (target, name) ->
  error 'Target ' .. target .. 'does not exist' if not commands[target]
  commands[name] = target

get = (name) -> commands[name]

names = -> [name for name in pairs commands]

command_completer = ->
  completion_options = list: {
    headers: { 'Command', 'Key binding', 'Description' }
    column_styles: { 'string', 'keyword', 'comment' }
  }
  cmd_names = names!
  bindings = {cmd, binding for binding, cmd in pairs keymap when type(cmd) == 'string'}
  table.sort cmd_names
  items = {}
  for name in *cmd_names
    def = commands[name]
    desc = type(def) == 'string' and "(Alias for #{def})" or def.description
    binding = bindings[name] or ''
    append items, { name, binding, desc }

  matcher = Matcher items
  (text) -> matcher(text), completion_options

run = (cmd_string = nil) ->
  cmd_completer = nil
  state = State!

  cmd_input =
    title: 'Command'
    should_complete: (_, text, readline) -> state\should_complete text, readline
    close_on_cancel: (_, text, readline) -> state\close_on_cancel text, readline
    update: (_, text, readline) -> state\update text, readline
    on_completed: (_, item, readline) -> state\on_completed item, readline
    on_submit: (_, text, readline) -> state\on_submit text, readline
    go_back: (_, readline) -> state\go_back readline

    complete: (_, text, readline) ->
      if state.cmd
        return state\complete(text, readline)
      else
        cmd_completer or= command_completer!
        cmd_completer text

  prompt = ':'
  text = nil

  if cmd_string and #cmd_string > 0
    state\update cmd_string .. ' '
    return if state\submit!
    prompt ..= state\to_string!
    text = cmd_string if not state.cmd

  window.readline\read prompt, cmd_input, (value, readline) ->
    if not value
      state\on_cancelled readline
      return

    state\update readline.text .. ' ', readline
    if state\submit value
      return true

    return false

  window.readline.text = text if text

return setmetatable { :register, :unregister, :alias, :run, :names, :get }, {
  __index: (key) => commands[key] or accessible_names[key]
}
