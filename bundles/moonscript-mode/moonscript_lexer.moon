howl.aux.lpeg_lexer ->

  keyword = capture 'keyword', word {
    'return', 'break', 'local', 'for', 'while', 'if', 'else', 'elseif', 'then',
    'export', 'import', 'from', 'with', 'in', 'and', 'or', 'not', 'class',
    'extends', 'super', 'do', 'using', 'switch', 'when', 'unless'
  }

  comment = capture 'comment', span('--', eol)

  sq_string = span("'", "'", '\\')
  dq_string = span('"', '"', '\\')
  long_string = span('[[', ']]', '\\')
  string = capture 'string', any { sq_string, dq_string, long_string }

  hexadecimal_number =  P'0' * S'xX' * xdigit^1 * (P'.' * xdigit^1)^0 * (S'pP' * S'-+'^0 * xdigit^1)^0
  float = digit^0 * P'.' * digit^1
  number = capture 'number', any({
    hexadecimal_number,
    (float + digit^1) * (S'eE' * P('-')^0 * digit^1)^0
  })

  operator = capture 'operator', any {
    S'+-*!\\/%^#=<>;:,.(){}[]',
    any { '~=', 'or=', 'and=' }
  }

  ident = (alpha + '_')^1 * (alpha + digit + '_')^0

  identifier = capture 'identifier', ident
  member = capture 'member', (P'@' + 'self.') * ident^0
  special = capture 'special', any { 'true', 'false', 'nil' }
  clazz = capture 'class', upper^1 * (alpha + digit + '_')^0
  key = capture 'key', any {
    P':' * ident,
    ident * P':',
    (sq_string + dq_string) * P':'
  }
  lua_keywords = capture 'error', word { 'function', 'goto', 'end' }

  any { number, key, string, comment, operator, special, keyword, member, clazz, lua_keywords, identifier }
