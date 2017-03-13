-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

StyledText = howl.ui.StyledText
append = table.insert

style_chunk_p = r '<(\\w+)>(.*?)</(?:\\1>|>)', {r.DOTALL}

(text) ->
  pos = 1
  len = #text
  styles = {}
  stripped_text = ''

  while pos <= len
    start_p, end_p, style, content = style_chunk_p\find text, pos

    unless start_p
      stripped_text ..= text\usub pos, len
      break

    unless start_p == pos
      stripped_text ..= text\usub pos, start_p - 1

    style_start = #stripped_text + 1
    append styles, style_start
    append styles, style
    append styles, style_start + #content
    stripped_text ..= content

    pos = end_p + 1

  StyledText stripped_text, styles
