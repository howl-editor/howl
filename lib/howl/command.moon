-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import dispatch, interact, config from howl
import Matcher from howl.util
import style, markup, StyledText from howl.ui

append = table.insert

style.define_default 'commandname', 'keyword'

commands = {}

resolve_command = (name) ->
  def = commands[name]
  def = commands[def.alias_for] if def and def.alias_for -- alias
  def

parse_cmd = (text) ->
  cmd_start, cmd_end, cmd, rest = text\find '^%s*([^%s]+)%s+(.*)$'
  return resolve_command(cmd), cmd, rest if cmd
  return nil, nil, text

register = (spec) ->
  for field in *{'name', 'description'}
    error 'Missing field for command: "' .. field .. '"' if not spec[field]

  if not (spec.factory or spec.handler) or (spec.factory and spec.handler)
    error 'One of "factory" or "handler" required'

  c = setmetatable moon.copy(spec), __call: (...) => spec.handler ...
  commands[spec.name] = c

unregister = (name) ->
  cmd = commands[name]
  return if not cmd
  commands[name] = nil

  aliases = {}
  for cmd_name, def in pairs commands
    append aliases, cmd_name if def.alias_for == name

  commands[alias] = nil for alias in *aliases

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

class CommandRunner
  run: (@finish, opts={}) =>
    @command_line = howl.app.window.command_line
    cmd = nil
    cmdname = ''
    @command_line.prompt = ':'
    @command_line.title = 'Command'
    if opts.directory
      @command_line.directory = opts.directory
    if opts.cmd_string
      @run_command opts.cmd_string

  run_command: (cmd_string) =>
    cmd, cmdname, text = parse_cmd cmd_string

    if cmd
      @command_line\write_spillover text
    else
      cmd = resolve_command cmd_string
      cmdname = cmd and cmd.name

    if not cmd
      @command_line.text = cmd_string
      log.error 'No such command'
      return

    @command_line\clear!
    @command_line.prompt = markup.howl "<prompt>:</><commandname>#{cmdname}</> "

    local results

    ok, error = pcall ->
      results = table.pack howl.app.window.command_line\run cmd

    if not ok
      log.error error

    self.finish results and unpack results

  on_update: (text) =>
    if text\find ' '
      @run_command text

  command_completion: =>
    text = @command_line.text
    @command_line\clear!
    cmdname = interact.select_command
      :text
      title: 'Command'

    if cmdname
      @run_command cmdname

  run_historical: =>
    text = @command_line.text
    @command_line\clear!
    @command_line\write_spillover text
    cmdname = interact.select_historical_command!
    if cmdname
      @run_command cmdname

  keymap:
    tab: => @command_completion!
    up: => @run_historical!
    ctrl_r: => @run_historical!
    escape: => self.finish!
    enter: =>
      if @command_line.text
        @run_command @command_line.text
      else
        @command_completion!

command_runner = {
  name: 'command-runner'
  factory: CommandRunner
}

run = (cmd_string = nil, opts={}) ->
  if not howl.app.window
    error "Cannot run command '#{cmd_string}', application not initialized. Try using the 'app-ready' signal.", 2

  cmd_string = nil if cmd_string == 'run'
  command_line = howl.app.window.command_line
  if opts.submit
    command_line\run_auto_submit command_runner, cmd_string: cmd_string, directory: opts.directory
  else
    command_line\run command_runner, cmd_string: cmd_string, directory: opts.directory

howl.interact.register
  name: 'select_command'
  description: 'Selection list for all commands'
  evade_history: true
  handler: (opts={}) ->
    with opts
      .items = get_command_items!
      .headers = { 'Command', 'Key binding', 'Description' }
      .columns = {
        { style: 'string' }
        { style: 'keyword' }
        { style: 'comment' }
      }
      .submit_on_space = true

    result = interact.select opts

    if result
      return result.selection[1]

get_command_history = ->
  howl.app.window.command_line.command_history

interact.register
  name: 'select_historical_command'
  description: 'Selection list for previously run commands'
  evade_history: true
  handler: ->
    line_items = {}
    for idx, item in ipairs get_command_history!
      table.insert line_items, {idx, item, command: tostring(item)}
    result = interact.select
      matcher: Matcher line_items, preserve_order: true
      reverse: true
      title: 'Command History'
    if result
      return result.selection.command\sub 2

return { :register, :unregister, :alias, :run, :names, :get }
