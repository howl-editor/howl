-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import styler from howl
import PropertyObject from howl.aux.moon

class Chunk extends PropertyObject
  new: (@buffer, @start_pos, @end_pos) =>
    super!

  @property text:
    get: =>
      @_text or= @buffer\usub(@start_pos, @end_pos)
      @_text

    set: (text) =>
      @buffer\as_one_undo ->
        @delete!
        @buffer\insert text, @start_pos
        @end_pos = @start_pos + #text - 1

  @property styles:
    get: =>
      unless @_styles
        b_start, b_end = @buffer\byte_offset(@start_pos), @buffer\byte_offset(@end_pos)
        @_styles = styler.reverse @buffer, b_start, b_end

      @_styles

  delete: => @buffer\delete @start_pos, @end_pos if @end_pos >= @start_pos

  @meta {
    __tostring: => @text
    __len: => (@end_pos - @start_pos) + 1
  }

return Chunk
