import styler from howl
import PropertyObject from howl.aux.moon

class Chunk extends PropertyObject
  new: (@buffer, @start_pos, @end_pos) =>
    super!

  @property text:
    get: =>
      @buffer.text\usub(@start_pos, @end_pos)
    set: (text) =>
      @buffer\as_one_undo ->
        @delete!
        @buffer\insert text, @start_pos
        @end_pos = @start_pos + #text - 1

  @property styles:
    get: =>
      b_start, b_end = @buffer\byte_offset @start_pos, @end_pos
      styler.styles_for_range @buffer, b_start, b_end

  delete: => @buffer\delete @start_pos, @end_pos if @end_pos >= @start_pos

  @meta {
    __tostring: => @text
    __len: => (@end_pos - @start_pos) + 1
  }

return Chunk
