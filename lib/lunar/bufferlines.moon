import config from lunar

line_mt =
  __index: (k) =>
    getter = @_getters[k]
    return getter self if getter

    f = rawget string, k
    if f
      return (_, ...) -> f @text, ...

  __newindex: (k, v) =>
    setter = @_setters[k]
    if setter
      setter self, v
      v
    else
      rawset self, k, v

  __tostring: => @text
  __len: => #@text
  __eq: (op1, op2) -> tostring(op1) == tostring(op2)

Line = (nr, buffer, sci) ->
  text = ->
    contents = sci\get_line nr - 1
    (contents\gsub '[\n\r]*$', '')

  setmetatable {
    :nr
    indent: => @indentation += config.get 'indent', buffer
    unindent: =>
      new_indent = @indentation - config.get 'indent', buffer
      if new_indent >= 0
        @indentation = new_indent

    _getters:
      text: => text!
      start_pos: => sci\position_from_line(nr - 1) + 1
      end_pos: => sci\position_from_line(nr)
      indentation: =>  sci\get_line_indentation nr - 1
      previous: => if nr > 1 then Line nr - 1, buffer, sci
      next: => if nr < sci\get_line_count! then Line nr + 1, buffer, sci
      empty: => #text! == 0
      blank: => @match('^%s*$') != nil

    _setters:
      text: (value) =>
        error 'line text can not be set to nil', 2 if value == nil
        line = nr - 1
        start = sci\position_from_line line
        end_pos = sci\get_line_end_position line
        sci\delete_range start, end_pos - start
        sci\insert_text start, value
      indentation: (indent) =>  sci\set_line_indentation nr - 1, indent

  }, line_mt

BufferLines = (buffer, sci) ->
  setmetatable {
      :buffer
      :sci

      delete: (start_line, end_line) =>
        -- zero based indexes below
        start_pos = sci\position_from_line(start_line - 1)
        end_pos = sci\position_from_line(end_line)
        @sci\delete_range start_pos, end_pos - start_pos

      range: (start_line, end_line) =>
        lines = {}
        for line = start_line, end_line
          append lines, self[line]
        lines

      at_pos: (pos) =>
        nr = @sci\line_from_position(pos - 1) + 1
        self[nr]

      insert: (line_nr, text) =>
        cur_line = self[line_nr]
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
      __len: => @sci\get_line_count!

      __index: (key) =>
        if type(key) == 'number'
          return nil if key < 1 or key > #self
          Line key, @buffer, @sci

      __newindex: (key, value) =>
        if type(key) != 'number' or (key < 1) or (key > #self)
          error 'Invalid index: "' .. key .. '"'

        line = self[key]
        if value
          line.text = value
        else
          @sci\delete_range line.start_pos - 1, (line.end_pos - line.start_pos) + 1

      __ipairs: =>
        iterator = (lines, index) ->
          index += 1
          line = lines[index]
          return nil if not line
          return index, line

        return iterator, self, 0

      __pairs: => ipairs self

return setmetatable {}, __call: (_, buffer, sci) -> BufferLines buffer, sci
