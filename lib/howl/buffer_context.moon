-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import Chunk from howl
import PropertyObject from howl.aux.moon
import style from howl.ui

class Context extends PropertyObject
  new: (@buffer, @pos) =>
    super!

  @property word: get: =>
    return @_word if @_word
    start_pos, end_pos = @_get_word_boundaries!
    @_word = Chunk @buffer, start_pos, end_pos - 1
    @_word

  @property token: get: =>
    suffix = @suffix
    prefix = @prefix
    first = suffix[1]
    start_pos, end_pos = @pos, @pos - 1

    pfx_p, sfx_p = if first\match '%p' -- punctuation
      '%p+$', '^%p+'
    elseif first\match '%w' -- word
      '%w+$', '^%w+'
    elseif first\match '%S' -- non-blank
      '%S+$', '^%S+'

    if pfx_p
      i = prefix\ufind pfx_p
      start_pos = @pos - (#prefix - i + 1) if i

    if sfx_p
      _, i = suffix\ufind sfx_p
      end_pos = @pos + i - 1 if i

    Chunk(@buffer, start_pos, end_pos)

  @property line: get: =>
    @_line or= @buffer.lines\at_pos @pos
    @_line

  @property word_prefix: get: => @word.text\usub 1, @pos - @word.start_pos
  @property word_suffix: get: => @word.text\usub (@pos - @word.start_pos) + 1
  @property prefix: get: => @line\usub 1, (@pos - @line.start_pos)
  @property suffix: get: => @line\usub (@pos - @line.start_pos) + 1
  @property next_char: get: => @suffix[1]
  @property prev_char: get: => @prefix[-1]
  @property style: get: => style.at_pos @buffer, @pos

  @meta {
    __eq: (a, b) ->
      t = typeof a
      t == 'Context' and t == typeof(b) and a.buffer == b.buffer and a.pos == b.pos

    __tostring: => "Context<#{tostring @buffer}@#{@pos}>"
  }

  _get_word_boundaries: =>
    word_pattern = @buffer\config_at(@pos).word_pattern

    line_text = @line.text
    line_start_pos = @line.start_pos
    line_pos = @pos - line_start_pos + 1
    start_pos = 1
    while start_pos <= line_pos
      start_pos, end_pos = line_text\ufind word_pattern, start_pos
      break unless start_pos

      if start_pos <= line_pos and end_pos >= line_pos - 1
        return @line.start_pos + start_pos - 1, @line.start_pos + end_pos

      start_pos = end_pos + 1

    return @pos, @pos
