-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import PropertyObject from howl.aux.moon
import command from howl
aullar = require 'aullar'
ffi = require 'ffi'
ffi_string = ffi.string
{:max, :min} = math

class Cursor extends PropertyObject
  new: (@container, @selection) =>
    @view = container.view
    @cursor = @view.cursor if @view
    super!

  @property blink_interval:
    get: => @cursor.blink_interval
    set: (interval) => @cursor.blink_interval = interval

  @property style:
    get: => @cursor.style

    set: (style) =>
      @cursor.style = style
      if style == 'block'
        @selection.includes_cursor = true
      elseif style == 'line'
        @selection.includes_cursor = false

  @property pos:
    get: => @view.buffer\char_offset @cursor.pos
    set: (pos) =>
      buf = @view.buffer
      pos = buf.size + 1 if pos > buf.size + 1
      pos = 1 if pos < 1

      b_pos = min(@view.buffer\byte_offset(pos), @view.buffer.size + 1)
      @cursor.pos = b_pos

  @property line:
    get: => @cursor.line
    set: (line) => @cursor.line = line

  @property column:
    get: =>
      @_line\virtual_column @column_index

    set: (col) =>
      error "Invalid column: #{col}", 2 if col < 1
      line = @_line
      col_index = line\real_column col
      @cursor.column = line\byte_offset col_index

  @property column_index:
    get: =>
      @_line\char_offset @cursor.column

    set: (index) =>
      @cursor.column = @_line\byte_offset index

  @property at_end_of_line:
    get: => @column_index > #@_line

  @property at_start_of_line:
    get: => @column_index == 1

  @property at_end_of_file:
    get: => @cursor.pos > @container.buffer.size

  move_to: (opts = {}) =>
    if opts.pos
      @cursor\move_to pos: @container.buffer\byte_offset(opts.pos), extend: opts.extend
    else
      lines = @container.buffer.lines
      line = opts.line or @line
      error "Invalid line #{line}" if line > #lines
      b_line = lines[line]
      col_index = opts.column_index
      unless col_index
        col_index = opts.column and b_line\real_column(opts.column) or 1

      b_col_index = b_line\byte_offset(col_index) or b_line.size
      @cursor\move_to :line, column: b_col_index, extend: opts.extend

  home_indent: (extend = false) =>
    col = @_line\find '%S'
    @move_to column_index: col, :extend

  home_indent_auto: (extend = false) =>
    col = @_line\find '%S'
    col = 1 if col == @column_index
    @move_to column_index: col, :extend

  word_right: (extend = false) =>
    if @at_end_of_line
      unless @at_end_of_file
        @move_to line: @line + 1, :extend
        @home_indent extend
    else
      text = @_line.text
      i = @column_index

      -- see if we have any current word as specified by the configuration
      cur_word = @container.buffer\context_at(@pos).word
      -- but if not, or if the word is before the cursor, just scan forward
      if cur_word.end_pos < @pos and not text[i].is_blank
        p = text[i]\match('^%p$') and '%p+' or '[^%p%s]+'
        _, end_pos =  text\ufind p, i
        i = end_pos and end_pos + 1 or i + 1
      else -- start the final scan after the current word
        i += (cur_word.end_pos - @pos) + 1

      -- eat up any space up to the next token
      _, _, end_pos = text\ufind '^%s*()', i
      @move_to column_index: (end_pos or i), :extend

  word_right_end: (extend = false) =>
    ctx = @container.buffer\context_at(@pos)
    text = ctx.suffix
    if text.is_blank and @line != @view.buffer.nr_lines
      @move_to line: @line + 1, :extend
      @word_right_end extend
    else
      cur_word = ctx.word

      -- do we have a current word that extends past our pos?
      if cur_word.end_pos >= @pos
        @move_to pos: cur_word.end_pos + 1, :extend
      else
         -- eat up space from next char until next token
        _, _, i = text\ufind '^%s*()', 2
        -- do we have a new word at this pos?
        word_pattern = @container.buffer\config_at(@pos).word_pattern
        start_pos, end_pos = text\ufind(word_pattern, i)
        if not end_pos or start_pos != i -- no
          _, end_pos = text\ufind('^%p+', i)
          _, end_pos = text\ufind('^%w+', i) unless end_pos
          end_pos or= #text

        @move_to column_index: end_pos + @column_index, :extend

  word_left: (extend = false) =>
    ctx = @container.buffer\context_at(@pos)

    if ctx.prefix.is_blank
      if @line == 1
        @cursor\move_to(pos: 1, :extend) if @column_index != 1
      else
        prev_line = @container.buffer.lines[@line - 1]
        @cursor\move_to pos: prev_line.byte_end_pos, :extend
    else
      cur_word = ctx.word
      if cur_word.start_pos < @pos
        @move_to pos: cur_word.start_pos, :extend
      else
        text = ctx.prefix\match '(.-)%s*$'
        last_group = text\ufind '%S+$'
        if last_group -- scan for a previous word first
          word_pattern = @container.buffer\config_at(@pos).word_pattern
          word_start, word_end = text\ufind word_pattern, last_group
          while word_end and word_end < text.ulen
            word_start, word_end = text\ufind word_pattern, word_end + 1

          if word_start
            @move_to column_index: word_start, :extend
            return

        col = text\ufind(r'(?:[\\pP\\pS]+|\\d+)\\s*$')
        col or= text\find('%w[%w_]*%s*$')

        @move_to column_index: col or 1, :extend

  word_left_end: (extend = false) =>
    ctx = @container.buffer\context_at(@pos)
    text = ctx.prefix
    cur_word = ctx.word
    local i

    if cur_word.start_pos < @pos
      i = (cur_word.start_pos - @_line.start_pos) + 1
    else
      i = text\ufind '%p+$' -- prev block is punctuation?
      i or= text\ufind '%w[%w_]*$' -- other word token?

    text = text\usub(1, i - 1) if i
    i = text\umatch '%S+()%s+$' -- previous blank with something before?

    if i -- then move to the end of whatever it is
      @move_to column_index: i, :extend
    elseif text.is_blank
      if @line == 1
        @cursor\move_to(pos: 1, :extend) if @column_index != 1
      else
        prev_line = @container.buffer.lines[@line - 1]
        col = prev_line\ufind('%s*$') or 1
        @move_to line: prev_line.nr, column_index: col, :extend
    else
      @move_to column_index: #text + 1, :extend

  para_up: (extend = false) =>
    line = @_line
    line = line.previous_non_blank if line.is_blank
    line = line.previous_blank if line

    if line
      @move_to line: line.nr, :extend
    else
      @move_to pos: 1, :extend

  para_down: (extend = false) =>
    line = @_line
    line = line.next_non_blank if line.is_blank
    line = line.next_blank if line

    if line
      @move_to line: line.nr, :extend
    else
      @cursor\end_of_file :extend

  -- private

  @property _line: get: =>
    @container.buffer.lines[@cursor.line]

commands = {
  { 'down',               'down',        'Moves cursor down' },
  { 'up',                 'up',          'Move cursor up' },
  { 'left',               'backward',        'Moves cursor left' },
  { 'right',              'forward',       'Moves cursor right' },
  { 'word_left',          'word_left',        'Moves cursor one word left' },
  { 'word_left_end',      'word_left_end',    'Moves cursor left, to the end of the previous word' },
  { 'word_right',         'word_right',       'Moves cursor one word right' },
  { 'word_right_end',     'word_right_end',   'Moves cursor right, to the end of the word' },
  { 'home',               'start_of_line',             'Moves cursor to the first column' },
  { 'home_indent',        'home_indent',           'Moves cursor to the first non-blank column' }, -- { 'home_indent_display','vchome_display',   'Moves cursor to the first non-blank column of the display line' },
  -- { 'home_display',       'home_display',     'Moves cursor to the first column of the display line' },
  -- { 'home_auto',          'home_wrap',        'Moves cursor the first column of the real or display line' },
  { 'home_indent_auto',   'home_indent_auto',      'Moves cursor the first column or the first non-blank column' },
  { 'line_end',           'end_of_line',         'Moves cursor to the end of line' },
  -- { 'line_end_display',   'line_end_display', 'Moves cursor to the end of the display line' },
  -- { 'line_end_auto',      'line_end_wrap',    'Moves cursor to the end of the real or display line' },
  { 'start',              'start_of_file',    'Moves cursor to the start of the buffer' },
  { 'eof',                'end_of_file',     'Moves cursor to the end of the buffer' },
  { 'page_up',            'page_up',          'Moves cursor one page up' },
  { 'page_down',          'page_down',        'Moves cursor one page down' },
  { 'para_down',          'para_down',        'Moves cursor one paragraph down' },
  { 'para_up',            'para_up',          'Moves cursor one paragraph up' },
}

for cmd in *commands
  name, key_cmd, description = cmd[1], cmd[2], cmd[3]
  f = aullar.Cursor[key_cmd]

  unless Cursor.__base[name]
    Cursor.__base[name] = (extend_selection) =>
      opts = extend_selection and {extend: true} or {}
      f @cursor, opts

  cmd_name = name\gsub '_', '-'
  command.register
    name: "cursor-#{cmd_name}"
    :description
    handler: ->
      howl.app.editor.cursor[name] howl.app.editor.cursor

  command.register
    name: "cursor-#{cmd_name}-extend"
    description: "#{description}, extending the selection"
    handler: -> howl.app.editor.cursor[name] howl.app.editor.cursor, true

return Cursor
