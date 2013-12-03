-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

pairs = pairs

howl.aux.lpeg_lexer ->
  c = capture

  ruby_pairs = {
    '(': ')'
    '{': '}'
    '[': ']'
  }

  capture_pair_as = (name) ->
    any [ (P(p1) * Cg(Cc(p2), name)) for p1, p2 in pairs ruby_pairs ]

  keyword = c 'keyword', -B'.' * word {
    'BEGIN', 'END', 'alias', 'and', 'begin', 'break', 'case'
    'class', 'def', 'defined?', 'do', 'else', 'elsif', 'end',
    'ensure', 'false', 'for', 'if', 'in', 'module', 'next',
    'nil', 'not', 'or', 'redo', 'rescue', 'retry', 'return',
    'self', 'super', 'then', 'true', 'undef', 'unless', 'until',
    'when', 'while', 'yield', '__FILE__', '__LINE__'
  }

  special = c 'special', word { 'private', 'protected', 'public' }

  embedded_doc = sequence {
    c('whitespace', eol),
    c('keyword', '=begin') * #space,
    c('comment', scan_until(eol * '=end')),
    c('whitespace', eol),
    c('keyword', '=end') * #space
  }
  comment = c 'comment', P'#' * scan_until(eol)
  operator = c 'operator', S'+-*/%!~&\\^=<>;:,.(){}[]|?'
  ident = (alpha + '_')^1 * (alpha + digit + S'_?!')^0
  symbol = c 'symbol', any {
    -B(':') * P':' * S'@$'^-1 * (ident + S'+-/*'),
    ident * ':' * #(-P(':'))

  }
  identifier = c 'identifier', ident
  member = c 'member', P'@' * ident^1
  global = c 'global', P'$' * (ident^1 + S'/_?$')
  constant = c 'constant', upper^1 * (upper + digit + '_')^0 * -(#lower)
  type = c 'type', upper^1 * (alpha + digit + '_')^0
  fdecl = c('keyword', 'def') * c('whitespace', space^1) * c('fdecl', ident)

  -- numbers
  hex_digit_run = xdigit^1 * (P'_' * xdigit^1)^0
  hexadecimal_number =  P'0' * S'xX' * hex_digit_run^1 * (P'.' * hex_digit_run^1)^0 * (S'pP' * S'-+'^0 * xdigit^1)^0

  oct_digit_run = R'07'^1 * (P'_' * R'07'^1)^0
  octal_number = P'0' * S'oO'^-1 * oct_digit_run^1

  binary_digit_run = S'01'^1 * (P'_' * S'01'^1)^0
  binary_number = P'0' * S'bB'^-1 * binary_digit_run^1

  digit_run = digit^1 * (P'_' * digit^1)^0
  float = digit_run^1 * '.' * digit_run^1
  integer = #R('19')^1 * digit_run^1

  char = P'?' * (P'\\' * alpha * '-')^0 * alpha

  number = c 'number', any {
    octal_number,
    hexadecimal_number,
    binary_number,
    char,
    (float + integer) * (S'eE' * P('-')^0 * digit^1)^0
  }

  sq_string = c 'string', any {
    span("'", "'", '\\'),
    P'%q' * capture_pair_as('sq_del') * scan_until_capture 'sq_del', '\\',
    P'%q' * paired(1, '\\'),
  }

  P {
    'all'

    all: any {
      number,
      symbol,
      V'string',
      V'regex',
      comment,
      V'wordlist',
      embedded_doc,
      V'heredoc',
      operator,
      fdecl,
      member,
      keyword,
      special,
      constant,
      type,
      global,
      identifier
    }

    string: sq_string +  V'dq_string'
    interpolation_base: any {
      number,
      symbol,
      V'string',
      V'regex',
      V'wordlist',
      operator,
      member,
      keyword,
      constant,
      type,
      global,
      identifier
    }
    interpolation_block: c('operator', '{') * (-P'}' * (V'interpolation_base' + 1))^0 * c('operator', '}')
    interpolation: c('operator', '#') * any( V'interpolation_block', member, global )

    dq_string_start: c 'string', any {
      Cg(S'"`', 'del'),
      P'%' * S'Qx' * any { capture_pair_as('del'), Cg(P(1), 'del') }
    }
    dq_string_end: c 'string', match_back('del')
    dq_string_chunk: c('string', scan_until_capture('del', '\\', '#')) * any {
      V'dq_string_end',
      V'interpolation' * V'dq_string_chunk',
      (c('string', '#') * V'dq_string_chunk')^-1
    }
    dq_string: V'dq_string_start' * V('dq_string_chunk') * V('dq_string_end')^0

    regex_start: c 'regex', any {
      Cg('/', 're_del'),
      P'%r' * capture_pair_as 're_del',
      P'%r' * Cg(P(1), 're_del')
    }
    regex_end: c 'regex', match_back('re_del')
    regex_chunk: c('regex', scan_until_capture('re_del', '\\', '#')) * any {
      V'regex_end',
      V'interpolation' * V'regex_chunk',
      (c('regex', '#') * V'regex_chunk')^-1
    }
    regex_modifiers: c 'special', lower^0
    regex: V'regex_start' * V('regex_chunk') * V('regex_end')^0 * V'regex_modifiers'

    heredoc_end: c('string', eol) * S(' \t')^0 * c('constant', match_back('hd_del'))
    heredoc_chunk: c('string', scan_until(V'heredoc_end' + '#', '\\')) * any {
      V'interpolation' * V'heredoc_chunk',
      (c('string', '#') * V'heredoc_chunk')^-1
    }
    heredoc_tail: match_until eol, V'all' + c('whitespace', S(' \t')^1) + c('default', 1)
    heredoc_sq: c('constant', P"'" * Cg(scan_until("'"), 'hd_del') * P"'") * V'heredoc_tail' * c('string', scan_until(V'heredoc_end'))
    heredoc_dq: c('constant', S'`"' * Cg(scan_until(S'`"'), 'hd_del') * S'`"') * V'heredoc_tail' * V'heredoc_chunk'
    heredoc_bare: c('constant', Cg(scan_until(space + S',.'), 'hd_del')) * V'heredoc_tail' * V('heredoc_chunk')
    heredoc: sequence {
      c('operator', '<<'),
      #complement(space),
      c('constant', '-')^-1,
      any(V'heredoc_sq', V'heredoc_dq', V'heredoc_bare'),
      V('heredoc_end')^0,
      Cg('', 'hd_del') -- cancel out any outside (stacked) heredocs
    }

    wordlist_start: c('operator', '%w') * capture 'operator', any {
      capture_pair_as 'wl_del',
      Cg(P(1), 'wl_del'),
    }
    wordlist_chunk: -match_back('wl_del') * any {
      c('whitespace', S(' \t')^1),
      c('string', complement(S(' \t') + match_back('wl_del'))^1),
    }
    wordlist: V'wordlist_start' * V('wordlist_chunk')^0
  }
