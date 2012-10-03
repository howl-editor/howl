class MoonscriptMode
  new: =>
    lexer_file = bundle_file 'moonscript_lexer.lua'
    @lexer = lunar.aux.ScintilluaLexer 'moon', lexer_file

  after_newline: (line, editor) =>
    indent_patterns = {
      '[-=]>%s*$',
      '[{:=]%s*$',
      'class%s+%a+%s*$',
    }
    prev_line = line.previous
    for p in *indent_patterns
      if prev_line\match p
        line\indent!

    if line\match '^%s*}%s*$'
      wanted_indent = line.indentation
      editor\unindent!
      new_line = editor.buffer.lines\insert line.nr, ''
      new_line.indentation = wanted_indent

return MoonscriptMode
