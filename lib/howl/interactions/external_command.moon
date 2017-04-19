-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, interact, sys from howl
import File from howl.io
import ListWidget, markup from howl.ui
import file_matcher, get_cwd, get_dir_and_leftover from howl.util.paths
append = table.insert

_command_history = {}

available_commands = ->
  commands = {}
  for path in sys.env.PATH\gmatch '[^:]+'
    dir = File path
    if dir.exists
      append commands, child.basename for child in *dir.children

  return commands

text_parts = (text) ->
  parts = [p for p in text\gmatch '%S+']
  append parts, '' if text\ends_with ' '
  parts

last_text_part = (text) ->
  parts = text_parts text
  parts[#parts]

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

class ExternalCommandEntry
  run: (@finish, @opts={}) =>
    @command_line = app.window.command_line
    @commands = nil
    @list_widget = nil
    @auto_show_list = true

    directory = File @opts.path if @opts.path
    directory or= get_cwd!
    error "No such directory: #{directory}" unless directory.is_directory

    @command_line\clear_all!
    @command_line\disable_auto_record_history!
    @command_line.title = @opts.title or 'Command'
    @_chdir directory

  on_update: (text) =>
    if @list_widget and @list_widget.showing
      @_update_auto_complete!
    elseif @auto_show_list
      if text\umatch '^%s*cd%s+'
        @_auto_complete_file directories_only: true
      elseif looks_like_path last_text_part @command_line.text
        @_auto_complete_file!

  _chdir: (directory) =>
    @directory = directory
    trailing = directory.path == File.separator and '' or File.separator
    @command_line.prompt = markup.howl "<operator>[</><directory>#{@directory.short_path}#{trailing}</><operator>] $</> "

  _updir: =>
    if @directory.parent
      @_chdir @directory.parent

  _initialize_list_widget: =>
    @list_widget = ListWidget nil, never_shrink: true
    @list_widget.max_height_request = math.floor app.window.allocated_height * 0.5
    @list_widget.columns =  { {style: 'filename'} }
    @command_line\add_widget 'completion_list', @list_widget

  _auto_complete_file: (opts={}) =>
    unless @list_widget
      @_initialize_list_widget!

    unless @list_widget.showing
      @list_widget\show!

    if opts.directories_only
      @directory_reader = (dir) ->
        dirs = [c for c in *dir.children when c.is_directory]
        append dirs, 1, dir\join '.'
        dirs
    else
      @directory_reader = (dir) -> dir.children

    @_update_auto_complete!

  _update_auto_complete: =>
    return unless @list_widget and @list_widget.showing
    last_part = last_text_part @command_line.text

    unless last_part
      @list_widget\hide!
      return

    path, unmatched = get_dir_and_leftover @directory.path .. File.separator .. last_part
    @list_widget.matcher = file_matcher self.directory_reader(path), path
    @list_widget\update unmatched
    @list_widget_path = path
    @list_widget_unmatched = unmatched

  _auto_complete_command: (text) =>
    @commands or= available_commands!

    if @list_widget
      @list_widget\hide!

    selected = interact.select
      items: @commands
      title: 'Commands'
      columns: { { style: 'string' } }
      submit_on_space: true
      cancel_on_backspace: true
      :text

    if selected
      @command_line\write selected.selection
      @command_line\write ' '

  _select_completion: =>
    @list_widget\hide!
    return unless @list_widget.selection

    filename = @list_widget.selection.name
    new_path = @list_widget_path / filename
    @command_line.text = @command_line.text\sub(1, -#@list_widget_unmatched - 1)
    @command_line\write filename
    unless new_path.is_directory
      @command_line\write ' '
      @list_widget\hide!

  _submit: =>
    unless @command_line.text == _command_history[1]
      append _command_history, 1, @command_line.text
    -- remove prompt so correct history is catpured
    @command_line.prompt = ''
    @command_line\record_history!
    self.finish @directory.path, @command_line.text

  _select_from_history: =>
    text = @command_line.text
    @command_line.text = ''

    result = interact.select
      items: _command_history
      title: 'Previous commands'
      reverse: true
      :text
      allow_new_value: true

    if result
      @command_line.text = result.selection or result.text
    else
      @command_line.text = text

  keymap:
    enter: =>
      unless @list_widget and @list_widget.showing
        return @_submit!

      text = @command_line.text
      cd_cmd = text\umatch '^%s*cd%s+'

      if cd_cmd and (not @list_widget.selection or @list_widget.selection.name == './')
          dir = @command_line.text\umatch '^%s*cd%s+(.+)'
          dir = File.expand_path dir
          path = @directory / dir
          if path.exists and path.is_directory
            @_chdir path
            @list_widget\hide!
            @command_line.text = ''
          return

      @_select_completion!

    binding_for:
      ["cancel"]: =>
        if @list_widget and @list_widget.showing
          @list_widget\hide!
          @auto_show_list = false
        else
          self.finish!

    tab: =>
      @auto_show_list = true
      if looks_like_path last_text_part @command_line.text
        @_auto_complete_file!
      else
        space, cmd = @command_line.text\umatch '^(%s*)(%S*)$'
        if @command_line.text.is_empty or cmd
          @command_line.text = space if space
          @_auto_complete_command cmd
        else
          @_auto_complete_file!

    backspace: =>
      if @command_line.text.is_empty
        @_updir!
      else
        return false

    up: =>
      return false if @list_widget and @list_widget.showing
      @_select_from_history!

interact.register
  name: 'get_external_command',
  description: 'Returns a directory and a command to run within the directory',
  factory: ExternalCommandEntry
