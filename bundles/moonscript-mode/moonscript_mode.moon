indent_patterns = {
  '[-=]>%s*$',
  '[{([:=]%s*$',
  { '^%s*if%s+', 'then' },
  { '^%s*else%s*$', 'then' },
  { '^%s*elseif%s+', 'then' },
  { '^%s*while%s+', 'then' },
  { '^%s*unless%s+', 'then' },
  { '^%s*switch%s+' },
  { '^%s*do%s*' },
  { '^%s*with%s+' },
  'class%s+%a+',
}

class MoonscriptMode
  new: =>
    lexer_file = bundle_file 'moonscript_lexer.lua'
    @lexer = lunar.aux.ScintilluaLexer 'moon', lexer_file
    @completers = { 'same_buffer' }

  short_comment_prefix: '--'

  indent_for: (line, indent_level, editor) =>
    prev_line = line.previous
    while prev_line and prev_line.empty
      prev_line = prev_line.previous

    return line.indentation unless prev_line

    for p in *indent_patterns
      negative = nil
      positive = p

      if type(p) == 'table'
        positive = p[1]
        negative = p[2]

      if prev_line\match positive
        if not negative or not prev_line\match negative
          return prev_line.indentation + indent_level

    return prev_line.indentation

  after_newline: (line, editor) =>
    if line\match '^%s*}%s*$'
      wanted_indent = line.indentation
      editor\shift_left!
      new_line = editor.buffer.lines\insert line.nr, ''
      new_line.indentation = wanted_indent

return MoonscriptMode
