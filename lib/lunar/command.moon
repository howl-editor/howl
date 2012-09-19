import inputs, config from lunar
import Matcher from lunar.completion

accessible_name = (name) ->
  name\lower!\gsub '[%s%p]+', '_'

commands = {}
accessible_names = {}

register = (spec) ->
  for field in *{'name', 'description', 'handler'}
    error 'Missing field for command: "' .. field .. '"' if not spec[field]

  c = setmetatable moon.copy(spec),
    __call: (...) => spec.handler ...

  commands[spec.name] = c
  sane_name = accessible_name spec.name
  accessible_names[sane_name] = c if sane_name != spec.name

unregister = (name) ->
  cmd = commands[name]
  return if not cmd
  commands[name] = nil

  aliases = {}
  for name, target in pairs commands
    append aliases, name if target == cmd

  commands[alias] = nil for alias in *aliases
  sane_name = accessible_name name
  accessible_names[sane_name] = nil if sane_name != name

alias = (target, name) ->
  error 'Target ' .. target .. 'does not exist' if not commands[target]
  commands[name] = commands[target]

get = (name) -> commands[name]

names = -> [name for name in pairs commands]

parse_arguments = (text) ->
  [ part for part in text\gmatch '%S+' ]

parse_cmd = (text) ->
  cmd_start, cmd_end, cmd, rest = text\find '^%s*([^%s]+)[^%w_](.*)$'
  if cmd then return commands[cmd], rest

complete_for_command = (state, text, readline) ->
  if state.current_input
    return state.current_input\complete text, readline
  else
    return if true

  cmd = state.cmd

  arguments = parse_arguments text
  input_index = math.max #arguments, 1
  input = state.inputs[input_index]

  if not input
    state.current_input = nil
    if not cmd.inputs then return {}
    input_type = cmd.inputs[input_index]
    if not input_type then return {}
    input_factory = inputs[input_type]
    if not input_factory then error 'Could not find input for `' .. input_type .. '`'
    input = input_factory readline
    append state.inputs, input
    state.current_input = input

  return input\complete arguments[#arguments], readline

complete_available_commands = (text, matcher) ->
  completion_options = list: headers: { 'Command', 'Description' }
  candidates = matcher text
  completions = [{name, commands[name].description} for name in *candidates]
  return completions, completion_options

load_input = (state, input_index, readline) ->
  cmd = state.cmd
  input = state.inputs[input_index]

  if not input
    state.current_input = nil
    return false if not cmd.inputs
    input_type = cmd.inputs[input_index]
    return false if not input_type
    input_factory = inputs[input_type]
    if not input_factory then error 'Could not find input for `' .. input_type .. '`'
    input = input_factory readline
    append state.inputs, input
    state.current_input = input

  true

update_state = (state, text, readline) ->
  if not state.cmd
    state.cmd, text = parse_cmd text
    return if not state.cmd
    readline.prompt ..= readline.text
    readline.text = text or ''

  args = parse_arguments text
  count = #args
  if count <= 1 and not state.current_input
    load_input state, 1, readline
  else
    for index, arg in ipairs args
      break if not load_input state, #state.arguments + 1, readline
      append state.arguments, arg if index != count

run = ->
  cmd_matcher = nil
  state = inputs: {}, arguments: {}

  cmd_input =
    should_complete: (_, text, readline) ->
      input = state.current_input
      if input and input.should_complete then return input\should_complete text, readline
      return config.complete == 'agressive'

    update: (_, text, readline) ->
      update_state state, text, readline

    complete: (_, text, readline) ->
      if state.cmd
        return complete_for_command state, text, readline
      else
        cmd_matcher = cmd_matcher or Matcher names!, true, true, true
        return complete_available_commands text, cmd_matcher

    on_completed: (_, text, readline) ->
      input = state.current_input
      if input and input.on_completed then input\on_completed text, readline

    go_back: (_, readline) ->
      input = state.current_input
      if input and input.go_back then input\go_back!

    value_for: (_, text) ->
      input = state.current_input
      if input and input.value_for
        input\value_for text
      else
        text

  window.readline\read ':', cmd_input, (value, readline) ->
    cmd = state.cmd
    if cmd
      append state.arguments, value
    else
      cmd = commands[value]

    return false if not cmd

    if #state.arguments >= #cmd.inputs
      cmd table.unpack state.arguments
      return true
    else
      readline.text ..= ' '
      update_state state, readline.text, readline

    return false

return setmetatable { :register, :unregister, :alias, :run, :names, :get}, {
  __index: (key) => commands[key] or accessible_names[key]
}
