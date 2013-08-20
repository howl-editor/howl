import Chunk from howl
import PropertyObject from howl.aux.moon

class Context extends PropertyObject
  new: (@buffer, @pos) =>
    @default_word_pattern = r'\\pL[\\pL\\d]*'
    super!

  @property word: get: =>
    return @_word if @_word
    start_pos, end_pos = @_get_word_boundaries!
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

  _get_word_boundaries: =>
    word_pattern = @buffer.mode.word_pattern or @default_word_pattern

    line_text = @line.text
    line_start_pos = @line.start_pos
    line_pos = @pos - line_start_pos + 1
    start_pos = 1
    while start_pos < line_pos
      start_pos, end_pos = line_text\ufind word_pattern, start_pos
      break unless start_pos

      if start_pos <= line_pos and end_pos >= line_pos - 1
        return @line.start_pos + start_pos - 1, @line.start_pos + end_pos

      start_pos = end_pos + 1

    return @pos, @pos
