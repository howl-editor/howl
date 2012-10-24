import PropertyObject from lunar.aux.moon

class Chunk extends PropertyObject
  new: (buffer, start_pos, end_pos) =>
    @buffer = buffer
    @start_pos = start_pos
    @end_pos = end_pos
    super!

  @property text:
    get: =>
      @buffer.sci\get_text_range @start_pos - 1, @end_pos
    set: (text) =>
      @buffer\as_one_undo ->
        @delete!
        @buffer\insert text, @start_pos
        @end_pos = @start_pos + #text - 1

  delete: => @buffer\delete @start_pos, @end_pos - @start_pos + 1

  @meta {
    __tostring: => @text
    __len: => #@text
  }

return Chunk
