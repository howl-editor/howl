class LispMode
  new: =>
    @lexer = bundle_load('lisp_lexer.moon')

  short_comment_prefix: ';'

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
  }

  indent_for: (line, indent_level) =>
    prev_line = line.previous_non_blank
    indentation = line.indentation

    if prev_line
      opening = prev_line\count '('
      closing = prev_line\count ')'
      if opening > closing
        indentation = prev_line.indentation + indent_level
      elseif closing > opening
        indentation = prev_line.indentation - indent_level
      else
        indentation = prev_line.indentation

    alignment_adjustment = indentation % indent_level
    indentation - alignment_adjustment

  structure: (editor) =>
    buffer = editor.buffer
    lines = {}
    patterns = {
      '%s*%(def%w+%s'
      '%s*%(ns%s'
    }

    for line in *buffer.lines
      for pattern in *patterns
        if line\match pattern
          append lines, line
          break

    lines
