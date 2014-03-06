-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

howl.aux.lpeg_lexer ->
  c = capture
  ident = (alpha + '_')^1 * (alpha + digit + '_')^0
  ws = c 'whitespace', blank

  identifer = c 'identifer', ident

  keyword = c 'keyword', word {
    'break', 'case', 'catch', 'continue', 'debugger', 'default', 'delete',
    'do', 'else', 'finally', 'for', 'function', 'if', 'in', 'instanceof',
    'new', 'return', 'switch', 'this', 'throw', 'try', 'typeof', 'var',
    'void', 'while', 'with'
  }

  operator = c 'operator', S'+-*/%=<>&^|!(){}[];'

  comment = c 'comment', any {
    P'//' * scan_until eol,
    span '/*', '*/'
  }

  number = c 'number', any {
    float,
    hexadecimal,
    digit^1,
    word('Nan', 'Infinity')
  }

  special = c 'special', word('undefined', 'null', 'true', 'false')

  str = any {
    span('"', '"', '\\')
    span("'", "'", '\\')
  }
  string = c 'string', str

  type = c 'type', upper^1 * (alpha + digit + '_')^0
  key = c 'key', any(str, ident) * ':'

  regex = sequence {
    c('regex', sequence {
      '/',
      scan_to(any('/', eol), '\\'),
      B('/'),
    }),
    c('operator', S'gim'^1)^0
  }

  fdecl = any {
    c('keyword', 'function') * ws^1 * c('fdecl', ident),
    sequence {
      -B(alpha),
      c('fdecl', ident),
      ws^0,
      c('operator', '='),
      ws^0,
      any {
        c('keyword', 'new') * ws^1 * c('type', 'Function'),
        c('keyword', 'function') * #(blank^0 * '(')
      }
    }
  }

  any {
    comment,
    key,
    string,
    regex,
    fdecl,
    keyword,
    special,
    operator,
    number,
    type,
    identifer,
  }
