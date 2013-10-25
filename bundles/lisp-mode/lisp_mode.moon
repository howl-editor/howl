find_start = (line, opening) ->
  closing = {v, k for k, v in pairs opening}
  stack = {}
  last = nil

  while line
    s = line.text

    for i = #s, 1, -1
      c = s[i]
      if c == last
        if #stack == 1 and i == 1
          return line, i, c, 'even'

        stack[#stack] = nil
        last = stack[#stack]
      elseif opening[c] and not closing[c]
        return line, i, c, 'open'
      else
        starter = closing[c]
        if starter
          stack[#stack + 1] = starter
          last = starter

    line = line.previous_non_blank

class LispMode
  new: =>
    @lexer = bundle_load('lisp_lexer')

  short_comment_prefix: ';'

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
  }

  indent_for: (line, indent_level) =>
    indentation = 0
    prev_line = line.previous_non_blank

    if prev_line
      indentation = prev_line.indentation

      start_line, col, brace, status = find_start prev_line, @auto_pairs
      if start_line
        if status == 'even'
          indentation = col - 1
        elseif status == 'open'
          if brace == '('
            -- align with following form on the same line if present
            -- _, form_start = start_line\ufind '^%S+%s+[({]', col + 1
            form_start = false
            if form_start
              indentation = form_start - 1
            else
              prev_char = start_line[col - 1]
              if prev_char == "`" or prev_char == "'" -- quoted form
                indentation = col + indent_level - 2
              else
                indentation = col + indent_level - 1
          else -- [ {
            indentation = col

    indentation

  structure: (editor) =>
    buffer = editor.buffer
    lines = {}
    patterns = {
      '^%(def'
      '%s*%(ns%s'
    }

    for line in *buffer.lines
      for pattern in *patterns
        if line\match pattern
          append lines, line
          break

    lines
