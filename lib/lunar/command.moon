import inputs, config from lunar
import Matcher from lunar.util

commands = {}
accessible_names = {}

-- command state
parse_arguments = (text) ->
  [ part for part in text\gmatch '(%S+)%s' ]

parse_cmd = (text) ->
  cmd_start, cmd_end, cmd, rest = text\find '^%s*([^%s]+)%s+(.*)$'
  if cmd then return commands[cmd], cmd, rest
  else return nil, nil, text

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

    for index, arg in ipairs parse_arguments text
      break unless @_ensure_input_loaded #@arguments + 1
      append @arguments, arg
      readline.prompt ..= arg .. ' ' if readline

    if #@inputs <= #@arguments
      @_ensure_input_loaded #@arguments + 1, readline

  should_complete: (text, readline) =>
    should = @_dispatch 'should_complete', text, readline
    return should != nil and should or config.complete == 'always'

  complete: (text, readline) => @_dispatch 'complete', text, readline
  on_completed: (text, readline) => @_dispatch 'on_completed', text, readline
  go_back: (readline) => @_dispatch 'go_back', readline

  _dispatch: (handler, ...) =>
    if @current_input and @current_input[handler]
      return self.current_input[handler] @current_input, ...

  submit: (value) =>
    cmd = @cmd or commands[value]
    return false if not cmd

    if #@arguments >= #cmd.inputs
      values = {}
      for i = 1, #@arguments
        input = @inputs[i]
        value = @arguments[i]
        value = input\value_for(value) if input.value_for
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
      @current_input = nil
      return false if not @cmd.inputs
      input_type = @cmd.inputs[input_index]
      return false if not input_type
      input_factory = inputs[input_type]
      if not input_factory then error 'Could not find input for `' .. input_type .. '`'
      input = input_factory!
      append @inputs, input
      @current_input = input

    true

-- command interface

accessible_name = (name) ->
  name\lower!\gsub '[%s%p]+', '_'

register = (spec) ->
  for field in *{'name', 'description', 'handler'}
    error 'Missing field for command: "' .. field .. '"' if not spec[field]

  c = setmetatable moon.copy(spec),
    __call: (...) => spec.handler ...
  c.inputs = c.inputs or {}

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

complete_available_commands = (text, matcher) ->
  completion_options = list: headers: { 'Command', 'Description' }
  candidates = matcher text
  completions = [{name, commands[name].description} for name in *candidates]
  return completions, completion_options

run = (cmd_string = nil) ->
  cmd_matcher = nil
  state = State!

  cmd_input =
    should_complete: (_, text, readline) -> state\should_complete!
    update: (_, text, readline) -> state\update text, readline
    on_completed: (_, text, readline) -> state\on_completed text, readline
    go_back: (_, readline) -> state\go_back readline


    complete: (_, text, readline) ->
      if state.cmd
        return state\complete(text, readline)
      else
        cmd_names = names!
        table.sort cmd_names
        cmd_matcher = cmd_matcher or Matcher cmd_names, true, true, true
        return complete_available_commands text, cmd_matcher

  prompt = ':'
  text = nil

  if cmd_string and #cmd_string > 0
    state\update cmd_string .. ' '
    return if state\submit!
    prompt ..= state\to_string!
    text = cmd_string if not state.cmd

  window.readline\read prompt, cmd_input, (value, readline) ->
    state\update readline.text .. ' ', readline
    if state\submit value
      return true

    return false

  window.readline.text = text if text

return setmetatable { :register, :unregister, :alias, :run, :names, :get}, {
  __index: (key) => commands[key] or accessible_names[key]
}
