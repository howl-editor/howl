-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import dispatch, interact, config from howl
import Matcher from howl.util
import style, markup, StyledText from howl.ui

append = table.insert

style.define_default 'command_name', 'keyword'

commands = {}

resolve_command = (name) ->
  def = commands[name]
  def = commands[def.alias_for] if def and def.alias_for -- alias
  def

parse_cmd = (text) ->
  cmd_start, cmd_end, cmd_name, rest = text\find '^%s*([^%s]+)%s+(.*)$'
  return resolve_command(cmd_name), cmd_name, rest if cmd_name

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
    cmd_name = ''
    @command_line.prompt = ':'
    @command_line.title = 'Command'
    if opts.directory
      @command_line.directory = opts.directory
    if opts.cmd_string
      cmd = resolve_command opts.cmd_string
      if cmd
        @run_command cmd, opts.cmd_string
      else
        @command_line\write opts.cmd_string
        @on_update opts.cmd_string

  on_update: (cmd_string) =>
    return unless cmd_string\find ' '

    cmd, cmd_name, text = parse_cmd cmd_string

    if not cmd
      @command_line.text = cmd_string
      log.error "No such command '#{cmd_string}'"
      return

    if not cmd.interactive
      @command_line.text = cmd_name
      log.error "Command '#{cmd_name}' takes no arguments, press <enter> to run."
      return

    @run_command cmd, cmd_name, text

  run_command: (cmd, cmd_name, spillover) =>
    if cmd.interactive
      @command_line.title = 'Loading...'
      @command_line\show!

    @command_line\clear!
    @command_line.prompt = markup.howl "<prompt>:</><command_name>#{cmd_name}</> "
    if spillover
      @command_line\write_spillover spillover

    local results

    ok, err = pcall ->
      results = table.pack howl.app.window.command_line\run cmd

    if not ok
      log.error err

    self.finish(results and unpack results)

  command_completion: =>
    text = @command_line.text
    @command_line\clear!
    cmd_name = interact.select_command
      :text
      title: 'Command'

    if cmd_name
      cmd = resolve_command(cmd_name)
      @run_command cmd, cmd_name, nil

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
        @run_command cmd, @command_line.text, nil

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
    opts = moon.copy opts
    with opts
      .items = get_command_items!
      .headers = { 'Command', 'Key binding', 'Description' }
      .columns = {
        { style: 'string' }
        { style: 'keyword' }
        { style: 'comment' }
      }
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
      append line_items, {idx, item, command: tostring(item)}

    result = interact.select
      matcher: Matcher line_items, preserve_order: true
      reverse: true
      title: 'Command History'

    if result
      return result.selection.command\sub 2

return { :register, :unregister, :alias, :run, :names, :get }
