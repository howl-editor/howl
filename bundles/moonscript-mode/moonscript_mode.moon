class MoonscriptMode
  new: =>
    lexer_file = bundle_file 'moonscript_lexer.lua'
    @lexer = bundle_load('moonscript_lexer.moon')

  short_comment_prefix: '--'

  indent_patterns: {
    '[-=]>%s*$', -- fdecls
    '[([{:=]%s*$' -- hanging operators
    r'^\\s*\\b(class|switch|do|with|for|when)\\b', -- block starters
    { r'^\\s*\\b(elseif|if|while|unless)\\b', '%sthen%s*'}, -- conditionals
    '^%s*else%s*$',
    { '=%s*if%s', '%sthen%s*'} -- 'if' used as rvalue

  }

  dedent_patterns: {
    r'^\\s*(else|\\})\\s*$',
    { '^%s*elseif%s', '%sthen%s*' }
  }

  after_newline: (line, editor) =>
    if line\match '^%s*}%s*$'
      wanted_indent = line.indentation
      editor\shift_left!
      new_line = editor.buffer.lines\insert line.nr, ''
      new_line.indentation = wanted_indent
      with editor.cursor
        .line = line.nr
        .column = wanted_indent + 1

return MoonscriptMode
