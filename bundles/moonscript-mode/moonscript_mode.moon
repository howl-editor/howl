indent_patterns = {
  '[-=]>%s*$',
  '[{:=]%s*$',
  { '^%s*if%s+', 'then' },
  { '^%s*else%s*$', 'then' },
  { '^%s*while%s+', 'then' },
  { '^%s*unless%s+', 'then' },
  'class%s+%a+',
}

class MoonscriptMode
  new: =>
    lexer_file = bundle_file 'moonscript_lexer.lua'
    @lexer = lunar.aux.ScintilluaLexer 'moon', lexer_file
    @completers = { 'same_buffer' }

  short_comment_prefix: '--'

  indent_for: (line, editor) =>
    prev_line = line.previous
    while prev_line and prev_line.empty
      prev_line = prev_line.previous

    return unless prev_line

    for p in *indent_patterns
      negative = nil
      positive = p

      if type(p) == 'table'
        positive = p[1]
        negative = p[2]

      if prev_line\match positive
        if not negative or not prev_line\match negative
          return '->'

    nil

  after_newline: (line, editor) =>
    if line\match '^%s*}%s*$'
      wanted_indent = line.indentation
      editor\unindent!
      new_line = editor.buffer.lines\insert line.nr, ''
      new_line.indentation = wanted_indent

return MoonscriptMode
