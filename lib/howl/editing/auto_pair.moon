import config from howl

uneven_count = (s, character) ->
  count = 0
  pos = 1

  while pos
    _, pos = s\find character, pos, true
    if pos
      count += 1
      pos += 1

  count % 2 == 1

start_character = (character, auto_pairs) ->
  for start_c, end_c in pairs auto_pairs
    return start_c if character == end_c
  nil

handle = (event, editor) ->
  buffer = editor.buffer
  auto_pairs = buffer.mode.auto_pairs
  char = event.character
  return unless auto_pairs and buffer.config.auto_pair and char

  mate = auto_pairs[char]
  context = editor.current_context
  next_char = context.next_char
  same_chars = char == mate
  overwrite_check = next_char == char

  if mate
    return if r'\\p{L}'\match next_char
    return if same_chars and uneven_count context.line.text, char

    if not same_chars or not overwrite_check or uneven_count context.line.text, char
      pos = editor.cursor.pos
      buffer\insert "#{char}#{mate}", pos

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
    description: 'Whether to automatically insert a matching companion character when possible'
    default: true
    type_of: 'boolean'

return :handle