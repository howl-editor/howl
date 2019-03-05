-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.util.lpeg_lexer ->
  c = capture
  ident = (alpha + '_')^1 * (alpha + digit + '_')^0
  ws = c 'whitespace', blank

  identifer = c 'identifer', ident

  keyword = c 'keyword', -B'.' * word {
    'async', 'await', 'break', 'case', 'catch', 'class', 'const', 'continue',
    'debugger', 'default', 'delete', 'do', 'else', 'export', 'extends',
    'finally', 'from', 'for', 'function', 'if', 'import', 'in', 'instanceof',
    'let', 'new', 'of', 'return', 'super', 'switch', 'throw', 'try',
    'typeof', 'var', 'void', 'while', 'with', 'yield'
  }

  operator = c 'operator', S'+-*/%=<>&^|!(){}[].,?:;'

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

  special = c 'special', word {'undefined', 'null', 'true', 'false'}

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
    c('operator', S'gimuy'^1)^0,
    #sequence {
      blank^0,
      any(S',;.)', P(-1))
    }
  }

  classdef = c('keyword', 'class') * ws * c('type_def', ident)

  fdecl = any {
    c('keyword', 'function') * (ws^0 * c 'operator', '*')^0 * ws^1 * c('fdecl', ident),
    sequence {
      -B(alpha),
      c('fdecl', ident),
      ws^0,
      c('operator', '='),
      ws^0,
      any {
        c('keyword', 'new') * ws^1 * c('type', 'Function'),
        c('keyword', 'function') * #(blank^0 * (c('operator', '*') * blank^0)^0 * '(')
      }
    }
  }

  member = sequence {
    c 'member', word { 'this' }
    (c('operator', P'.') * c('member', ident))^0
  }

  P {
    'all'

    all: any {
      comment,
      key,
      V'template',
      string,
      regex,
      classdef,
      fdecl,
      member,
      keyword,
      special,
      operator,
      number,
      type,
      identifer,
    }

    template: sequence {
      c 'special', ident^-1
      c 'string', '`'
      V'template_chunk'
    }

    template_chunk: sequence {
      c 'string', scan_until (P'`' + '${'), '\\'
      any {
        c 'string', '`'
        P(-1)
        sequence {
          any {
            V'template_interpolation'
            c 'string', P 1
          }
          V'template_chunk'
        }
      }
    }

    template_interpolation: sequence {
      c 'operator', '${'
      ((c('string', space + eol) + V'all' + P 1) - '}')^0
      c 'operator', '}'
    }
  }
