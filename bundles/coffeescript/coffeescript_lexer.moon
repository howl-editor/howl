-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

r = r

howl.aux.lpeg_lexer ->
  c = capture

  keyword = c 'keyword', -B'.' * word {
    -- shared with JS
    'new', 'delete', 'typeof', 'instanceof', 'in',
    'return', 'throw', 'break', 'continue', 'debugger'
    'if', 'else', 'switch', 'for', 'while', 'do', 'try', 'catch', 'finally'
    'class', 'extends', 'super'

    -- Coffee specific
    'undefined', 'then', 'unless', 'until', 'loop', 'off', 'by', 'when'
    'and', 'or', 'isnt', 'is', 'not', 'yes', 'no', 'on', 'of'
  }

  reserved = c 'error', -B'.' * word {
      'case', 'default', 'function', 'var', 'void', 'with', 'const', 'let', 'enum'
    'export', 'import', 'native', '__hasProp', '__extends', '__slice', '__bind'
    '__indexOf', 'implements', 'interface', 'package', 'private', 'protected'
    'public', 'static', 'yield'
  }

  special = c 'special', any { 'true', 'false', 'null', 'this' }

  comment = c 'comment', any {
    span('###', '###'),
    span('#', eol)
  }

  number = c 'number', any {
    float,
    hexadecimal,
    digit^1,
    word('Nan', 'Infinity')
  }

  operator = c 'operator', S'+-*!\\/%^#=<>;:,.(){}[]'

  ident = (alpha + '_')^1 * (alpha + digit + '_')^0

  identifier = c 'identifier', ident
  member = c 'member', (P'@' + 'this.') * ident^0
  clazz = c 'class', upper^1 * (alpha + digit + '_')^0
  constant = c 'constant', B'.' * upper^1 * (upper + '_')^0 * #-alpha

  sq_string = span("'", "'", '\\')
  dq_string = span('"', '"', P'\\')

  key = c 'key', any {
    P':' * ident,
    ident * P':',
    (sq_string + dq_string) * P':'
  }

  javascript = sequence {
    c('operator', '`'),
    sub_lex('javascript', '`'),
    c('operator', '`'),
  }

  ws = c 'whitespace', blank^0

  P {
    'all'
    all: any {
      number, key, V'string', comment, V'regex', operator, special, keyword, member,
      constant, clazz, reserved, V'fdecl', identifier, javascript
    }
    string: any {
      c('string', span("'''", "'''")),
      c('string', sq_string),
      V'dq_string'
    }
    interpolation: c('operator', '#') * (-P'}' * (V'all' + 1))^1 * c('operator', '}') * V'dq_string_chunk'
    dq_string_chunk: sequence {
      c('string', scan_until_capture('dq_del', '\\', '#{')),
      any {
        c('string', match_back('dq_del')),
        V('interpolation')^0
      }
    }
    dq_string: c('string', Cg(any('"""', '"'), 'dq_del')) * (V'dq_string_chunk')
    multi_re_del: c('regex', '///')
    multi_re_interpolation: sequence {
      c('regex:operator', '#{'),
      sub_lex('coffeescript', '}'),
      c('regex:operator', '}')
    }
    multi_re_chunk: c('regex', scan_until(any('///', '#'))) * any {
      V'multi_re_del',
      V'multi_re_interpolation' * V'multi_re_chunk',
      #P'#' * sub_lex('coffeescript', eol) * V'multi_re_chunk'
      -1 -- EOT
    }
    regex_modifiers: c 'special', lower^0
    single_line_re: sequence {
      c('regex', P'/' * scan_until(any(eol, '/'), '\\') * P'/'),
      V'regex_modifiers'
    }
    regex: sequence {
      #P('/'),
      last_token_matches r'[[,=(\\D]$',
      any {
        V'multi_re_del' * V('multi_re_chunk'),
        V'single_line_re',
      },
      -#(blank^0 * any(digit, alpha))
    }
    fdecl: sequence {
      c('fdecl', ident),
      ws,
      c('operator', '='),
      ws,
      sequence({
        c('operator', '('),
        any({
          identifier,
          -#P')' * operator,
          special,
          c('whitespace', blank^1),
          number,
          V'string'
        })^0,
        c('operator', ')'),
        ws,
      })^0,
      c('operator', any('->', '=>')),
      }
    }
