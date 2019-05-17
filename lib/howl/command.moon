-- Copyright 2012-2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import dispatch, interact from howl
import style, markup from howl.ui

append = table.insert

style.define_default 'command_name', 'keyword'

commands = {}
accessible_names = {}

resolve_command = (name) ->
  -- return a command definition for a command name or an alias
  def = commands[name]
  def = commands[def.alias_for] if def and def.alias_for -- alias
  def

accessible_name = (name) ->
  name\lower!\gsub '[%s%p]+', '_'

parse_cmd = (text) ->
  cmd_name, rest = text\match '^%s*([^%s]+)%s+(.*)$'
  return resolve_command(cmd_name), cmd_name, rest if cmd_name

register = (cmd_def) ->
  for field in *{'name', 'description'}
    error 'Missing field for command: "' .. field .. '"' if not cmd_def[field]

  if not (cmd_def.factory or cmd_def.handler) or (cmd_def.factory and cmd_def.handler)
    error 'One of "factory" or "handler" required'

  cmd_def = moon.copy cmd_def
  commands[cmd_def.name] = cmd_def
  sane_name = accessible_name cmd_def.name
  accessible_names[sane_name] = cmd_def if sane_name != cmd_def.name

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

get_command_items = ->
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
    append items, { name, binding, desc, cmd_text: name }

  return items

history = {}  -- array of {styled_text:, text:} objects

record_history = (cmd_name, input_text) ->
  local styled_text, text
  if input_text and not input_text.is_empty
    styled_text = markup.howl("<command_name>:#{cmd_name}</> #{input_text}")
    text = "#{cmd_name} #{input_text}"
  else
    styled_text = markup.howl("<command_name>:#{cmd_name}</>")
    text = cmd_name

  item = {:styled_text, :text}

  -- don't duplicate repeated commands
  history = [h_item for h_item in *history when h_item.text != item.text]
  append history, 1, item

  -- prune
  if #history > 1000
    history = [history[i] for i=1,1000]

get_input_text = (cmd, input) ->
  -- convert the input object to input_text - a text representation of input used in the history
  -- this is done either via cmd.get_input_text function if present
  -- or using some simple heuristics
  if cmd.get_input_text
    return cmd.get_input_text input

  if typeof(input) == 'File'
    return input.short_path
  if type(input) == 'table' and input.input_text
    return input.input_text
  return tostring input

get_command_history = -> [{item.styled_text, text: item.text} for item in *history]

ensure_command_can_run = (cmd) ->
  unless howl.app.window
    error "Cannot run command '#{cmd}', application not initialized. Try using the 'app-ready' signal.", 3

launch_cmd = (cmd, args) ->
  dispatch.launch ->
    ok, err = pcall -> cmd.handler table.unpack args
    if not ok
      log.error err

run = (cmd_text=nil) ->
  -- run a command string, either immediately, or after asking for input if necessary
  capture_history = true

  ensure_command_can_run cmd_text
  cmd_text or= ''

  cmd, cmd_name, rest = parse_cmd cmd_text
  unless cmd
    cmd, cmd_name, rest = resolve_command(cmd_text), cmd_text, ''

  if cmd
    -- don't capture history for automatically selected commands that are run immediately
    capture_history = false

  -- if we couldn't resolve a command,
  -- or we resolved a command that doesn't take input, but we have extra command text
  -- then require command selection
  if not cmd or (not rest.is_empty and not cmd.input)
    cmd, cmd_name, rest = howl.interact.select_command text: cmd_text, prompt: ':'

  return unless cmd

  rest or= ''

  help = howl.ui.HelpContext!
  help\add_section heading: "Command '#{cmd.name}'", text: cmd.description

  -- the command definition may or may not have an input function
  if cmd.input
    -- invoke the input function to get input data and then invoke the handler
    inputs = table.pack cmd.input
      prompt: ':'..cmd_name..' '
      text: rest
      :help
    return if inputs[1] == nil -- input was cancelled

    -- record history
    input_text = get_input_text cmd, inputs[1]
    if input_text
      record_history cmd_name, input_text

    -- invoke handler
    cmd.handler table.unpack inputs

  else
    -- no input function, invoke the handler directly
    if capture_history
      record_history cmd_name, ''
    cmd.handler!

class CommandConsole
  new: =>
    @commands = get_command_items!

    -- compute column styles (including min_width) used for completion list
    name_width = 0
    shortcut_width = 0
    for item in *@commands
      name_width = math.max(name_width, item[1].ulen)
      shortcut_width = math.max(shortcut_width, item[2].ulen)
    @completion_columns = {{style: 'string', min_width: name_width}, {style: 'keyword', min_width: shortcut_width}, {style: 'comment'}}

  display_prompt: => ":"

  display_title: => "Command"

  complete: (text) =>
    word, spaces = text\match '^(%S+)(%s*)'
    if not spaces or spaces.is_empty
      return name: 'command', completions: @commands, match_text: word, columns: @completion_columns

  select: (text, item, completion_opts) =>
    @run item.cmd_text

  parse: (text) =>
    _, spaces = text\match '^(%S+)(%s*)'
    if spaces and not spaces.is_empty
      @run text
  run: (text) =>
    cmd_name, space, rest = text\match '^(%S+)(%s?)(.*)'

    cmd = resolve_command cmd_name
    if cmd
      if not space.is_empty and not cmd.input
        msg = "Command '#{cmd_name}' accepts no input - press <enter> to run.", 0
        return text: cmd_name, error: msg
      return result: {:cmd_name, :rest, :cmd}
    else
      error "No such command: #{cmd_name}"

  get_history: => get_command_history!

interact.register
  name: 'select_command'
  description: 'Selection list for all commands'
  handler: (opts={}) ->
    help = howl.ui.HelpContext!
    with help
      \add_section
        heading: "Command 'run'"
        text: 'Run a command'
      \add_section
        heading: 'Usage'
        text: 'Type a command name and press <keystroke>enter</> to run.'
      \add_keys
        tab: 'Show command list'
        up: 'Show command history'

    result = howl.app.window.command_panel\run howl.ui.ConsoleView(CommandConsole!), text: opts.text, :help
    return unless result
    result.cmd, result.cmd_name, result.rest

return setmetatable {:register, :unregister, :alias, :run, :names, :get, :record_history}, {
  __index: (key) =>
    command = commands[key] or accessible_names[key]
    return unless command
    ensure_command_can_run command.name
    (...) -> launch_cmd command, table.pack ...
}
