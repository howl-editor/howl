append = table.insert

class NimMode
  new: =>
    @lexer = bundle_load('nim_lexer')

  comment_syntax: '#'

  indentation: {
    more_after: {
      '[([{:=]%s*$'
      r'^\\s*\\b(const|enum|let|type|proc|func|iterator|macro|template|method|object|tuple|var)\\s*$',
    }

    same_after: {
      ',%s*$'
    }

    less_for: {
      authoritive: false
      r'^\\s*(else|elif|of)\\s*',
      '^%s*[]})]',
    }
  }

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
    "`": "`"
  }

  code_blocks:
    multiline: {
      { '{%s*$', '^%s*}', '}'}
      { '%[%s*$', '^%s*%]', ']'}
      { '%(%s*$', '^%s*%)', ')'}
    }

  structure: (editor) =>
    buffer = editor.buffer
    lines = {}

    patterns = {
      '^%s*type%s*$'
      '^%s*const%s*$'
      '^%s*proc%s+'
      '^%s*func%s+'
      '^%s*method%s+'
    }

    for line in *editor.buffer.lines
      for p in *patterns
        if line\umatch p
          append lines, line

    return lines

return NimMode
