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
    authoritive: false
    r'^\\s*(else|\\})\\s*$'
    { '^%s*elseif%s', '%sthen%s*' }
  }

  on_char_added: (args, editor) =>
    if args.key_name == 'return'
      return true if @_auto_format_after_newline(editor) == true

    @parent.on_char_added @, args, editor

  _auto_format_after_newline: (editor) =>
    line = editor.current_line
    prev_line = line.previous

    if prev_line\match('{%s*$') and line.text.stripped == '}'
      cur_indent = prev_line.indentation
      new_indent = cur_indent + editor.buffer.config.indent
      line.indentation = cur_indent
      new_line = editor.buffer.lines\insert line.nr, ''
      new_line.indentation = new_indent
      with editor.cursor
        .line = line.nr
        .column = new_indent + 1

      return true

return MoonscriptMode
