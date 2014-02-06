-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

howl.aux.lpeg_lexer ->
  c = capture

  keyword = c 'keyword', word {
     'and', 'break', 'do', 'elseif', 'else', 'end',
     'false', 'for', 'function',  'goto', 'if', 'in',
     'local', 'nil', 'not', 'or', 'repeat', 'return',
     'then', 'true', 'until', 'while'
  }

  bracket_quote_lvl_start = P'[' * Cg(P('=')^0, 'lvl') * '['
  bracket_quote_lvl_end = ']' * match_back('lvl') * ']'
  bracket_quote =  bracket_quote_lvl_start * scan_to(bracket_quote_lvl_end)^-1

  comment = c 'comment', '--' * any {
    bracket_quote,
    scan_until eol,
  }

  sq_string = span("'", "'", '\\')
  dq_string = span('"', '"', P'\\')

  string = c 'string', any {
    sq_string,
    dq_string,
    bracket_quote
  }

  operator = c 'operator', S'+-*!/%^#~=<>;:,.(){}[]'

  hexadecimal_number =  P'0' * S'xX' * xdigit^1 * (P'.' * xdigit^1)^0 * (S'pP' * S'-+'^0 * xdigit^1)^0
  float = digit^0 * P'.' * digit^1
  number = c 'number', any({
    hexadecimal_number,
    (float + digit^1) * (S'eE' * P('-')^0 * digit^1)^0
  })

  ident = (alpha + '_')^1 * (alpha + digit + '_')^0
  identifier = c 'identifier', ident
  constant = c 'constant', upper^1 * any(upper, '_', digit)^0 * any(eol, -#lower)

  special = c 'special', any {
    'true',
    'false',
    'nil',
    '_' * upper^1 -- variables conventionally reserved for Lua
  }

  ws = c 'whitespace', blank^0

  fdecl = any {
    sequence {
      c('keyword', 'function'),
      c 'whitespace', blank^1,
      c('fdecl', ident * (S':.' * ident)^-1)
    },
    sequence {
      c('fdecl', ident),
      ws,
      c('operator', '='),
      ws,
      c('keyword', 'function'),
      -#any(digit, alpha)
    }
  }

  cdef = sequence {
    any {
      sequence {
        c('identifier', 'ffi'),
        c('operator', '.'),
      },
      line_start
    },
    c('identifier', 'cdef'),
    c('operator', '(')^-1,
    ws,
    any {
      sequence {
        c('string', bracket_quote_lvl_start),
        sub_lex('c', bracket_quote_lvl_end),
        c('string', bracket_quote_lvl_end)^-1,
      },
      sequence {
        c('string', '"'),
        sub_lex('c', '"'),
        c('string', '"')^-1,
      },
      sequence {
        c('string', "'"),
        sub_lex('c', "'"),
        c('string', "'")^-1,
      }
    }
  }

  any {
    number,
    string,
    comment,
    operator,
    special,
    fdecl,
    keyword,
    cdef,
    constant,
    identifier
  }
