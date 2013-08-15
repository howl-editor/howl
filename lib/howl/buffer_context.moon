import Chunk from howl
import PropertyObject from howl.aux.moon

class Context extends PropertyObject
  new: (@buffer, @pos) => super!

  @property word: get: =>
    return @_word if @_word
    sci = @buffer.sci
    b_pos = @buffer\byte_offset @pos
    start_pos = sci\word_start_position b_pos - 1, true
    end_pos = sci\word_end_position b_pos - 1, true
    start_pos, end_pos = @buffer\char_offset start_pos + 1, end_pos + 1
    @_word = Chunk @buffer, start_pos, end_pos - 1
    @_word

  @property line: get: =>
    @_line or= @buffer.lines\at_pos @pos
    @_line

  @property word_prefix: get: => @word.text\usub 1, @pos - @word.start_pos
  @property word_suffix: get: => @word.text\usub (@pos - @word.start_pos) + 1
  @property prefix: get: => @line\usub 1, (@pos - @line.start_pos)
  @property suffix: get: => @line\usub (@pos - @line.start_pos) + 1
  @property next_char: get: => @suffix[1]
  @property prev_char: get: => @prefix[-1]

  @meta {
    __eq: (a, b) ->
      t = typeof a
      t == 'Context' and t == typeof(b) and a.buffer == b.buffer and a.pos == b.pos
  }
