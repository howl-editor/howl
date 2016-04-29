-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import config from howl

uneven_count = (s, character) ->
  count = 0
  pos = 1

  while pos
    _, pos = s\ufind character, pos, true
    if pos
      count += 1
      pos += 1

  count % 2 == 1

start_character = (character, auto_pairs) ->
  for start_c, end_c in pairs auto_pairs
    return start_c if character == end_c
  nil

handle_backspace = (event, editor, auto_pairs) ->
  context = editor.current_context
  prev_char = context.prev_char
  mate = auto_pairs[prev_char]
  if mate and context.next_char == mate
    buffer = editor.buffer
    buffer\as_one_undo ->
      pos = editor.cursor.pos
      buffer\delete pos - 1, pos
    true

handle = (event, editor) ->
  buffer = editor.buffer
  auto_pairs = editor.mode_at_cursor.auto_pairs
  char = event.character
  return unless auto_pairs and buffer.config.auto_pair and char
  return handle_backspace(event, editor, auto_pairs) if event.key_name == 'backspace'

  mate = auto_pairs[char]
  context = editor.current_context
  next_char = context.next_char
  same_chars = char == mate
  overwrite_check = next_char == char

  if mate
    selection = editor.selection

    unless selection.empty
      selection.text = "#{char}#{selection.text}#{mate}"
      return true

    return if r'\\p{L}'\match next_char
    return if same_chars and uneven_count context.line.text, char

    if not same_chars or not overwrite_check or uneven_count context.line.text, char
      pos = editor.cursor.pos
      buffer\insert "#{char}#{mate}", pos
      editor.cursor.pos = pos + char.ulen
    else
      editor.cursor\right!

    return true

  elseif overwrite_check
    start_c = start_character char, auto_pairs
    if start_c and context.line.text\match "%b#{start_c}#{char}"
      editor.cursor\right!
      return true

-- Config variables

with config
  .define
    name: 'auto_pair'
    description: 'Whether to handle certain matching pairs of characters automagically'
    default: true
    type_of: 'boolean'

return :handle
