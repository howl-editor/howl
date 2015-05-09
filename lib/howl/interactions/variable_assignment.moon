-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import Matcher from howl.util
import app, config, interact from howl
import ListWidget, NotificationWidget, StyledText from howl.ui

append = table.insert

parse_assignment = (text) ->
  name, val = text\match('%s*(%S+)%s*=%s*(%S.*)%s*')
  return name, val if name
  return text\match('%s*(%S+)%s*=')

stringify = (value, to_s) ->
  return to_s(value) if type(value) != 'table'
  [stringify o, to_s for o in *value]

option_completions = (def) ->
  options = def.options
  options = options! if callable options
  options = stringify options, def.tostring or tostring

  table.sort options, (a, b) ->
    return a < b if type(a) != 'table'
    return a[1] < b[1]

  columns = { { header: 'Option', style: 'string' } }
  if type(options[1]) == 'table'
    append columns, { header: 'Description', style: 'comment' }
  return options, columns

option_current_value = (def, options, current_buffer) ->
  cur_val = tostring current_buffer.config[def.name] or config.get def.name
  for option in *options
    if option == cur_val or (type(option) == 'table' and option[1] == cur_val)
      return option

option_caption = (name, current_buffer, def) ->
  to_s = def.tostring or tostring
  caption = StyledText def.description .. '\n\n', {}
  mode_val = current_buffer.mode.config and current_buffer.mode.config[name]
  value_table = StyledText.for_table {
    { "Global value:", to_s config[name] },
    { "For current mode:", to_s mode_val },
    { "For current buffer:", to_s current_buffer.config[name] }
  }, { {}, { style: 'string' } }
  return caption .. value_table

class VariableAssignment
  run: (@finish) =>
    @command_line = app.window.command_line
    vars = [{name, def.description} for name, def in pairs config.definitions]
    table.sort vars, (a, b) -> a[1] < b[1]
    @name_matcher = Matcher vars

    @list_widget = ListWidget @name_matcher, never_shrink: true
    @list_widget.max_height = app.window.allocated_height * 0.5
    @command_line\add_widget 'completion_list', @list_widget

    @caption_widget = NotificationWidget!
    @command_line\add_widget 'caption', @caption_widget
    @caption_widget.height_rows = 5
    @caption_widget\hide!
    @on_update ''

  on_update: (text) =>
    @caption_widget\hide!
    name, val = parse_assignment text
    if name
      def = config.definitions[name]
      unless def
        log.error "Unknown variable #{name}"
        return

      @command_line.title = name
      caption = option_caption name, app.editor.buffer, def
      if caption
        with @caption_widget
          \caption caption
          \show!

      if def.options
        if not @value_matcher
          options, columns = option_completions def
          @value_matcher = Matcher options
          @current_value = option_current_value def, options, app.editor.buffer
          with @list_widget
            .matcher = @value_matcher
            .columns = columns

        @list_widget\show! if not @list_widget.showing
        @list_widget\update val
        if not val or val.is_blank and @current_value
          @list_widget.selection = @current_value

      else
        @list_widget\hide! if @list_widget.showing
    else
      @value_matcher = nil
      @current_value = nil

      @command_line.title = 'Set Variable'

      with @list_widget
        .matcher = @name_matcher
        .columns = {
          { header: 'Variable', style: 'string' }
          { header: 'Description', style: 'comment' }
        }
        \show!
        \update text

  keymap:
    enter: =>
      name, val = parse_assignment @command_line.text
      if name
        if @list_widget.showing and @list_widget.selection
          val = @list_widget.selection
          @command_line.text = name .. '=' .. val
        self.finish
          name: name
          value: val
      else
        @command_line\clear!
        @command_line\write @list_widget.selection[1] .. '='

    escape: =>
      self.finish!

interact.register
  name: 'get_variable_assignment'
  description: 'Get config variable and value selected by user'
  factory: VariableAssignment
