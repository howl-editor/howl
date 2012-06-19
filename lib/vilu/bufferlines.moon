BufferLines = (sci) ->
  setmetatable :sci, :buffer
    __len: => @sci\get_line_count!

    __index: (key) =>
      if type(key) == 'number'
        return nil if key < 1 or key > #self
        text = @sci\get_line key - 1
        text\gsub '[\n\r]*$', ''

    __ipairs: =>
      iterator = (lines, index) ->
        index += 1
        text = lines[index]
        return nil if not text
        return index, text

      return iterator, self, 0

    __pairs: => ipairs self

return setmetatable {}, __call: (_, sci) -> BufferLines sci
