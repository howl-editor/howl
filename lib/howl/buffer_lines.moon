-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
ffi_string = ffi.string
import string, type from _G
append = table.insert
{:min, :max} = math

get_indentation = (text, config) ->
  leading = text\match '^%s*'
  spaces = leading\count ' '
  tabs = leading\count '\t'
  spaces + tabs * config.tab_width, #leading

line_mt =
  __index: (k) =>
    getter = @_getters[k]
    return getter self if getter

    v = @text[k]
    if v != nil
      return v unless type(v) == 'function'
      return (_, ...) -> v @text, ...

  __newindex: (k, v) =>
    setter = @_setters[k]
    if setter
      setter self, v
      v
    else
      rawset self, k, v

  __tostring: => @text
  __len: => @text.ulen
  __eq: (op1, op2) -> tostring(op1) == tostring(op2)

Line = (nr, buffer) ->
  a_buf = buffer._buffer

  get_line = -> a_buf\get_line nr
  text = -> get_line!.text

  setmetatable {
    :nr
    :buffer
    indent: => @indentation += buffer.config.indent

    unindent: =>
      buffer_indent = buffer.config.indent
      new_indent = max 0, @indentation - buffer_indent
      if new_indent != @indentation
        incorrect = new_indent % buffer_indent
        @indentation = new_indent + incorrect

    replace: (i, j, replacement) =>
      b_i, b_j = @byte_offset i, j + 1
      a_buf\replace @byte_start_pos + b_i - 1, (b_j - b_i), replacement

    real_column: (col) =>
      return 1 if col == 1
      line_text = text!
      error "Illegal column #{col}", 2 if col < 1
      tab_width = buffer.config.tab_width
      c_col = 1
      v_col = 1
      for i = 1, line_text.ulen
        v_col += (line_text[i] == '\t') and tab_width or 1
        c_col += 1
        break if v_col >= col

      c_col

    virtual_column: (col) =>
      return 1 if col == 1
      line_text = text!
      error "Illegal column #{col}" if col < 1 or col > line_text.ulen + 1
      nr_tabs = line_text\sub(1, col)\count('\t')
      return col if nr_tabs == 0
      col - nr_tabs + (nr_tabs * buffer.config.tab_width)

    _getters:
      text: => text!
      byte_start_pos: => get_line!.start_offset
      byte_end_pos: =>
        l = get_line!
        pos = l.end_offset
        pos += 1 unless l.has_eol or l.size == 0
        pos
      start_pos: => buffer\char_offset @byte_start_pos
      end_pos: => buffer\char_offset @byte_end_pos
      previous: => if nr > 1 then Line nr - 1, buffer, sci
      next: => if nr < a_buf.nr_lines then Line nr + 1, buffer, sci
      size: => get_line!.size
      has_eol: => get_line!.has_eol

      indentation: =>
        (get_indentation text!, @buffer.config)

      chunk: =>
        start_pos = @start_pos
        end_pos = @end_pos
        end_pos -= 1
        buffer\chunk start_pos, end_pos

      previous_non_blank: =>
        prev_line = @previous
        while prev_line and prev_line.is_blank
          prev_line = prev_line.previous
        prev_line

      previous_blank: =>
        prev_line = @previous
        while prev_line and not prev_line.is_blank
          prev_line = prev_line.previous
        prev_line

      next_non_blank: =>
        next_line = @next
        while next_line and next_line.is_blank
          next_line = next_line.next
        next_line

      next_blank: =>
        next_line = @next
        while next_line and not next_line.is_blank
          next_line = next_line.next
        next_line

    _setters:
      text: (value) =>
        error 'line text can not be set to nil', 2 if value == nil
        line = get_line!
        a_buf\replace line.start_offset, line.size, value

      indentation: (indent) =>
        config = @buffer.config
        cur_indent, real_indent = get_indentation text!, config
        return if indent == cur_indent

        content = text!\match '^%s*(.*)$'

        indent_s = if config.use_tabs
          nr_tabs = math.floor(indent / config.tab_width)
          string.rep('\t', nr_tabs) .. string.rep(' ', indent % config.tab_width)
        else
          string.rep ' ', indent

        @replace 1, real_indent, indent_s

  }, line_mt

BufferLines = (buffer) ->
  a_buf = buffer._buffer

  setmetatable {
      :buffer

      delete: (start_line, end_line) =>
        end_line = min end_line, a_buf.nr_lines
        return if end_line < start_line
        start_pos = a_buf\get_line(start_line).start_offset
        end_pos = a_buf\get_line(end_line).end_offset
        a_buf\delete start_pos, (end_pos - start_pos) + 1

      range: (start_line, end_line) =>
        s = math.min start_line, end_line
        e = math.max start_line, end_line
        lines = {}
        for line = s, e
          append lines, self[line]
        lines

      for_text_range: (start_pos, end_pos) =>
        s = math.min start_pos, end_pos
        e = math.max start_pos, end_pos
        start_line = @at_pos s
        return { start_line } if s == e
        end_line = @at_pos e

        end_line = end_line.previous if end_line.start_pos == e
        @range start_line.nr, end_line.nr

      at_pos: (pos) =>
        b_pos = buffer\byte_offset pos
        line = a_buf\get_line_at_offset b_pos
        self[line.nr]

      insert: (line_nr, text) =>
        cur_line = self[line_nr]
        if not cur_line
          return @append(text) if line_nr == #@ + 1
          error('Invalid line number "' .. line_nr .. '"', 2) if not cur_line

        text ..= @buffer.eol if not text\match '[\r\n]$'
        @buffer\insert text, cur_line.start_pos
        self[line_nr]

      append: (line_text) =>
        line_text ..= @buffer.eol if not line_text\match '[\r\n]$'
        last_line = self[#self]

        if #last_line > 0 and not last_line.text\match '[\r\n]$'
          line_text = @buffer.eol .. line_text

        @buffer\append line_text
        self[#self - 1]
    },
      __len: => a_buf.nr_lines

      __index: (key) =>
        if type(key) == 'number'
          return nil if key < 1 or key > #self
          Line key, @buffer

      __newindex: (key, value) =>
        if type(key) != 'number' or (key < 1) or (key > #self)
          error 'Invalid index: "' .. key .. '"', 2

        if value
          self[key].text = value
        else
          line = a_buf\get_line key
          a_buf\delete line.start_offset, line.full_size

      __ipairs: =>
        iterator = (lines, index) ->
          index += 1
          line = lines[index]
          return nil if not line
          return index, line

        return iterator, self, 0

      __pairs: => ipairs self

return setmetatable {}, __call: (_, buffer) -> BufferLines buffer
