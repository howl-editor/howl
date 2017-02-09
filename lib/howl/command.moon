-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import dispatch, interact from howl
import Matcher, safecall from howl.util
import style, markup from howl.ui

append = table.insert

style.define_default 'command_name', 'keyword'

commands = {}
accessible_names = {}

resolve_command = (name) ->
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
    append items, { name, binding, desc }

  return items

get_command_help = (cmd_name) ->
  cmd = resolve_command cmd_name
  return unless cmd

  heading = "Command '#{cmd_name}'"
  if cmd != commands[cmd_name]
    heading ..= ", alias for '#{cmd.name}'"

  keys = howl.bindings.keystrokes_for cmd_name
  if #keys == 0
    keys = howl.bindings.keystrokes_for cmd_name, 'editor'
  if #keys > 0
    heading ..= " (#{keys[1]})"
  return {
    :heading
    text: cmd.description
  }

class CommandInput
  run: (@finish, cmd_string='', @cmd_args) =>
    @command_line = howl.app.window.command_line
    @command_line.prompt = ':'
    @command_line.title = 'Command'
    @command_line.text = cmd_string

    if resolve_command cmd_string
      @on_update cmd_string .. ' '
    else
      @on_update cmd_string

  on_update: (cmd_string) =>
    return unless cmd_string\find ' '

    cmd, cmd_name, text = parse_cmd cmd_string

    if not cmd
      @command_line.text = cmd_string
      log.error "No such command '#{cmd_string}'"
      return

    if not cmd.input
      @command_line.text = cmd_name
      log.error "Command '#{cmd_name}' takes no input, press <enter> to run."
      return

    @command_line\write_spillover text
    @read_command_input cmd, cmd_name

  read_command_input: (cmd, cmd_name) =>
    @command_line\clear!
    @command_line.prompt = markup.howl "<prompt>:</><command_name>#{cmd_name}</> "
    help = {get_command_help cmd_name}
    @command_line\add_help(help) if help

    unless cmd.input
      @command_line\record_history!
      self.finish cmd, {}
      return

    input_reader =
      name: cmd.name
      handler: cmd.input

    results = table.pack howl.app.window.command_line\run input_reader, unpack @cmd_args

    if results.n > 0
      self.finish cmd, results
    else
      self.finish!

  command_completion: =>
    text = @command_line.text
    @command_line\clear!
    cmd_name = interact.select_command
      :text
      title: 'Command'

    if cmd_name
      cmd = resolve_command(cmd_name)
      @read_command_input cmd, cmd_name

  run_historical: =>
    text = @command_line.text
    @command_line\clear!
    @command_line\write_spillover text
    cmd_string = interact.select_historical_command!
    if cmd_string
      @command_line\write cmd_string.stripped

  keymap:
    tab: => @command_completion!
    up: => @run_historical!
    ctrl_r: => @run_historical!
    escape: => self.finish!
    enter: =>
      if @command_line.text
        cmd = resolve_command(@command_line.text)
        if not cmd
          log.error "No such command '#{@command_line.text}'"
          return
        @read_command_input cmd, @command_line.text

  help: {
    {
      heading: "Command 'run'"
      text: 'Run a command'
    }
    {
      text: markup.howl 'Type a command name and press <keystroke>enter</> to run.'
    }
    {
      key: 'tab'
      action: 'Show command list'
    }
    {
      key: 'up'
      action: 'Show command history'
    }
  }

command_input_reader = {
  name: 'command-input-reader'
  factory: CommandInput
}

launch_cmd = (cmd, args) ->
  dispatch.launch ->
    safecall nil, -> cmd.handler table.unpack args

run = (cmd_string=nil, ...) ->
  unless howl.app.window
    error "Cannot run command '#{cmd_string}', application not initialized. Try using the 'app-ready' signal.", 2

  local args
  cmd = resolve_command cmd_string

  if not cmd or cmd.input
    cmd, args = howl.app.window.command_line\run command_input_reader, cmd_string, table.pack ...
    return unless cmd
  else
    args = table.pack ...

  if cmd
    launch_cmd cmd, args

interact.register
  name: 'select_command'
  description: 'Selection list for all commands'
  evade_history: true
  handler: (opts={}) ->
    opts = moon.copy opts
    command_items = get_command_items!
    name_width = 0
    shortcut_width = 0
    for item in *command_items
      name_width = math.max(name_width, item[1].ulen)
      shortcut_width = math.max(shortcut_width, item[2].ulen)
    with opts
      .items = command_items
      .headers = { 'Command', 'Key binding', 'Description' }
      .columns = {
        { style: 'string', min_width: name_width }
        { style: 'keyword', min_width: shortcut_width }
        { style: 'comment' }
      }
    result = interact.select opts

    if result
      return result.selection[1]

get_command_history = ->
  howl.app.window.command_line\get_history 'command-input-reader'

interact.register
  name: 'select_historical_command'
  description: 'Selection list for previously run commands'
  evade_history: true
  handler: ->
    line_items = {}
    for idx, item in ipairs get_command_history!
      append line_items, {idx, item, command: tostring(item)}

    result = interact.select
      matcher: Matcher line_items, preserve_order: true
      reverse: true
      title: 'Command History'
      allow_new_value: true

    if result
      if result.selection
        return result.selection.command\sub 2
      else
        return result.text

return setmetatable {:register, :unregister, :alias, :run, :names, :get}, {
  __index: (key) =>
    command = commands[key] or accessible_names[key]
    return unless command
    (...) -> launch_cmd command, table.pack ...
}
