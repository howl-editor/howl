class MoonscriptMode
  new: =>
    lexer_file = bundle_file 'moonscript_lexer.lua'
    @lexer = lunar.aux.ScintilluaLexer 'moon', lexer_file
    @completers = { 'same_buffer' }

  after_newline: (line, editor) =>
    indent_patterns = {
      '[-=]>%s*$',
      '[{:=]%s*$',
      { '^%s*if%s+', 'then' },
      { '^%s*unless%s+', 'then' },
      'class%s+%a+%s*$',
    }
    prev_line = line.previous
    for p in *indent_patterns
      negative = nil
      positive = p

      if type(p) == 'table'
        positive = p[1]
        negative = p[2]

      if prev_line\match positive
        if not negative or not prev_line\match negative
          line\indent!

    if line\match '^%s*}%s*$'
      wanted_indent = line.indentation
      editor\unindent!
      new_line = editor.buffer.lines\insert line.nr, ''
      new_line.indentation = wanted_indent

return MoonscriptMode
