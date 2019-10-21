--- Copyright 2012-2018 The Howl Developers
--- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:app, :dispatch, :interact, :sys} = howl
{:StyledText} = howl.ui
{:File} = howl.io
{:file_list, :get_dir_and_leftover} = howl.util.paths

available_commands = ->
  commands = {}
  -- load commands in a separate coroutine using async becuase this can take a while sometimes
  dispatch.launch ->
    for path in sys.env.PATH\gmatch '[^:]+'
      dir = File path
      if dir.exists
        for child in *dir.children_async
          -- show command name in the first column and parent_dir in the second
          table.insert commands, {child.basename, child.parent.short_path}

  return commands

looks_like_path = (text) ->
  return unless text
  for p in *{
    '^%s*%./',
    '^%s*%.%./',
    '^%s*/',
    '^%s*~/',
  }
    if text\umatch p
      return true

files_under = (path) ->
  file_list path.children, path

directories_under = (path) ->
  dirs = [child for child in *path.children when child.is_directory]
  rows = file_list dirs, path
  if path.parent
    table.insert rows, 1, {StyledText('../', 'directory'), file: path.parent}
  table.insert rows, 1, {StyledText('./', 'directory'), file: path}
  return rows

normalized_relative_path = (from_path, to_path) ->
  relative = ''
  parent = from_path
  while parent
    if to_path\is_below parent
      return relative .. to_path\relative_to_parent parent
    else
      parent = parent.parent
      relative ..= '../'

class ExternalCommandConsole
  new: (@dir) =>
    error 'no dir specified for external command' unless @dir
    @dir = File(@dir) if type(@dir) == 'string'
    @available_commands = available_commands!

  display_prompt: => "[#{@dir.short_path}] $ "
  display_title: => "Command"

  complete: (text) =>
    -- parse into an array of {word:, trailing_spaces:} objects
    words = @_parse text
    if #words == 0 or (#words == 1 and words[1].word != 'cd' and not looks_like_path words[1].word)
      -- trying to auto complete a command
      match_text = if words[1] then words[1].word else ''
      return {
        name: 'command'
        completions: @available_commands
        :match_text
        columns: {{style: 'string'}, {style: 'comment'}}
      }

    elseif words[1].word == 'cd' and not words[1].trailing_spaces.is_empty
      path = if words[2] then words[2].word else ''
      matched_dir, match_text = @_parse_path path
      return name: 'cd', completions: directories_under(matched_dir), :match_text, auto_show: true

    elseif looks_like_path words[#words].word
      path = words[#words].word
      matched_dir, match_text = @_parse_path path
      return name: 'filepath', completions: files_under(matched_dir), :match_text, auto_show: true

  back: =>
    if @dir.parent
      @dir = @dir.parent

  _parse: (text) =>
    [:word, :trailing_spaces for word, trailing_spaces in text\gmatch '([^%s]+)([%s]*)']

  _parse_path: (path) =>
    local matched_dir, match_text
    if path.is_blank or path == '.' or path == '..'
      matched_dir = @dir
      match_text = path
    elseif path\ends_with File.separator
      matched_dir = @dir / path
      return unless matched_dir.exists and matched_dir.is_directory
      match_text = ''
    else
      matched_dir, match_text = get_dir_and_leftover tostring(@dir / path)
    return matched_dir, match_text

  _join: (words) =>
    parts = {}
    for w in *words
      table.insert parts, w.word
      table.insert parts, w.trailing_spaces
    return table.join parts

  select: (text, item, completion_opts) =>
    unless item
      return @run text

    if completion_opts.name == 'cd'
      if tostring(item[1]) == './'
        @dir = item.file
        return text: ''
      else
        relpath = normalized_relative_path @dir, item.file
        return text: "cd #{relpath}/"

    if completion_opts.name == 'command'
      -- commands are {commmand, parent_dir} tables
      return text: item[1] .. ' '

  run: (text) =>
    words = @_parse text

    if words[1].word == 'cd' and words[2]
      new_dir = @dir / words[2].word
      if new_dir.is_directory
        @dir = new_dir
        return text: ''
      else
        error 'No directory ' .. new_dir

    return result: {working_directory: @dir, cmd: text}


interact.register
  name: 'get_external_command'
  description: ''
  handler: (opts={}) ->
    console_view = howl.ui.ConsoleView ExternalCommandConsole opts.path or howl.io.File.home_dir
    app.window.command_panel\run console_view, text: opts.text
