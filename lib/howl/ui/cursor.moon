-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import PropertyObject from howl.aux.moon
import Scintilla, command from howl

class Cursor extends PropertyObject
  new: (@container, @selection) =>
    @sci = container.sci
    super!

  @property blink_interval:
    get: => @sci\get_caret_period!
    set: (interval) => @sci\set_caret_period interval

  @property style:
    get: =>
      cur_style = @sci\get_caret_style!
      if cur_style == Scintilla.CARETSTYLE_BLOCK then return 'block'
      elseif cur_style == Scintilla.CARETSTYLE_LINE then return 'line'
    set: (style) =>
      if style == 'block'
        @sci\set_caret_style Scintilla.CARETSTYLE_BLOCK
        @selection.includes_cursor = true
      elseif style == 'line'
        @sci\set_caret_style Scintilla.CARETSTYLE_LINE
        @selection.includes_cursor = false
      else error 'Invalid style ' .. style, 2

  @property pos:
    get: => 1 + @sci\char_offset(@sci\get_current_pos!)
    set: (pos) =>
      pos = #@container.buffer + 1 if pos > #@container.buffer + 1
      pos = 1 if pos < 1

      if @selection.persistent
        @selection\set @selection.anchor, pos
      else
        b_pos = @sci\byte_offset pos - 1
        @sci\goto_pos b_pos

      @sci\choose_caret_x!

  @property line:
    get: => 1 + @sci\line_from_position @sci\get_current_pos!
    set: (line) =>
      if line < 1 then @start!
      elseif line > @sci\get_line_count! then @eof!
      else @pos = 1 + @sci\char_offset @sci\position_from_line(line - 1)

  @property column:
    get: => 1 + @sci\get_column @sci\get_current_pos!
    set: (col) => @pos = 1 + @sci\char_offset @sci\find_column @line - 1, col - 1

  @property column_index:
    get: => @sci\count_characters(@sci\position_from_line(@line - 1), @sci\get_current_pos!) + 1
    set: (index) => with @sci
      base = \position_from_line(@line - 1)
      offset = \get_line(@line - 1)\byte_offset(index) - 1
      @pos = 1 + @sci\char_offset base + offset

  @property at_end_of_line:
    get: => @sci\get_line_end_position(@line - 1) == @sci\get_current_pos!

  @property at_start_of_line:
    get: => @column == 1

  move_to: (line, column) =>
    @line = line
    @column = column

  _adjust_persistent_selection_if_needed: =>
    return unless @selection.persistent and @selection.includes_cursor
    selection_start = @selection.persistent_anchor
    correct_anchor = @selection.cursor < selection_start and selection_start + 1 or selection_start
    @selection.anchor = correct_anchor if @selection.anchor != correct_anchor

commands = {
  { 'down',               'line_down',        'Moves cursor down' },
  { 'up',                 'line_up',          'Move cursor up' },
  { 'left',               'char_left',        'Moves cursor left' },
  { 'right',              'char_right',       'Moves cursor right' },
  { 'word_left',          'word_left',        'Moves cursor one word left' },
  { 'word_left_end',      'word_left_end',    'Moves cursor left, to the end of the word' },
  { 'word_part_left',     'word_part_left',   'Moves cursor left, to the start of word part' },
  { 'word_right',         'word_right',       'Moves cursor one word right' },
  { 'word_right_end',     'word_right_end',   'Moves cursor right, to the end of the word' },
  { 'word_part_right',    'word_part_right',  'Moves cursor right, to the start of the next word part' },
  { 'home',               'home',             'Moves cursor to the first column' },
  { 'home_indent',        'vchome',           'Moves cursor to the first non-blank column' },
  { 'home_indent_display','vchome_display',   'Moves cursor to the first non-blank column of the display line' },
  { 'home_display',       'home_display',     'Moves cursor to the first column of the display line' },
  { 'home_auto',          'home_wrap',        'Moves cursor the first column of the real or display line' },
  { 'home_indent_auto',   'vchome_wrap',      'Moves cursor the first column or the first non-blank column' },
  { 'line_end',           'line_end',         'Moves cursor to the end of line' },
  { 'line_end_display',   'line_end_display', 'Moves cursor to the end of the display line' },
  { 'line_end_auto',      'line_end_wrap',    'Moves cursor to the end of the real or display line' },
  { 'start',              'document_start',   'Moves cursor to the start of the buffer' },
  { 'eof',                'document_end',     'Moves cursor to the end of the buffer' },
  { 'page_up',            'page_up',          'Moves cursor one page up' },
  { 'page_down',          'page_down',        'Moves cursor one page down' },
  { 'para_down',          'para_down',        'Moves cursor one paragraph down' },
  { 'para_up',            'para_up',          'Moves cursor one paragraph up' },
}

for cmd in *commands
  name, key_cmd, description = cmd[1], cmd[2], cmd[3]
  plain = Scintilla[key_cmd]
  extended = Scintilla[key_cmd .. '_extend']

  Cursor.__base[name] = (extend_selection) =>
    if extend_selection or @selection.persistent
      extended @sci
      @_adjust_persistent_selection_if_needed!
    else
      plain @sci

  cmd_name = name\gsub '_', '-'
  command.register
    name: "cursor-#{cmd_name}"
    :description
    handler: -> howl.app.editor.cursor[name] howl.app.editor.cursor

  command.register
    name: "cursor-#{cmd_name}-extend"
    description: "#{description}, extending the selection"
    handler: -> howl.app.editor.cursor[name] howl.app.editor.cursor, true

return Cursor
