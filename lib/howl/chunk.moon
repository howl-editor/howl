-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import PropertyObject from howl.aux.moon

class Chunk extends PropertyObject
  new: (@buffer, @start_pos, @end_pos) =>
    super!

  @property empty: get: => @end_pos < @start_pos

  @property text:
    get: =>
      @_text or= @buffer\sub(@start_pos, @end_pos)
      @_text

    set: (text) =>
      @buffer\as_one_undo ->
        @delete!
        @buffer\insert text, @start_pos
        @end_pos = @start_pos + #text - 1

  @property styles:
    get: =>
      unless @_styles
        @_styles = if @empty
          {}
        else
          a_buf = @buffer._buffer
          b_start, b_end = a_buf\byte_offset(@start_pos), a_buf\byte_offset(@end_pos)
          a_buf\ensure_styled_to pos: b_end

          @_styles = @buffer._buffer.styling\get b_start, b_end

      @_styles

  delete: => @buffer\delete @start_pos, @end_pos unless @empty

  @meta {
    __tostring: => @text
    __len: => (@end_pos - @start_pos) + 1
  }

return Chunk
