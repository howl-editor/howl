-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

php = howl.aux.lpeg_lexer ->
  c = capture
  ident = (alpha + '_' + '$')^1 * (alpha + digit + '_')^0
  ws = c 'whitespace', blank

  identifier = c 'identifier', ident

  keyword = c 'keyword', word {
    '__halt_compiler', 'abstract', 'and', 'array', 'as',
    'break', 'bool', 'callable', 'case', 'catch', 'class',
    'clone', 'const', 'continue', 'declare', 'default',
    'die', 'do', 'echo', 'else', 'elseif',
    'empty', 'enddeclare', 'endfor', 'endforeach', 'endif',
    'endswitch', 'endwhile', 'eval', 'exit', 'extends',
    'final', 'finally', 'float', 'for', 'foreach', 'function',
    'global', 'goto', 'if', 'int', 'implements', 'include',
    'include_once', 'instanceof', 'insteadof', 'interface', 'isset',
    'list', 'namespace', 'new', 'object', 'or', 'print',
    'private', 'protected', 'public', 'require', 'require_once',
    'return', 'static', 'string', 'switch', 'throw', 'trait',
    'try', 'unset', 'use', 'var', 'while',
    'xor', 'yield',
  }

  operator = c 'operator', S('+-*/%=<>~&^|!(){}[];.')

  comment = c 'comment', any {
    any('//', '#') * scan_until eol,
    span('/*', '*/')
  }

  binary_number = P'0b' * S'01'^1
  php_float = any {
    float,
    digit^1 * (S'eE' * S('-+')^0 * digit^1)
  }

  number = c 'number', any {
    php_float,
    hexadecimal_float,
    hexadecimal,
    binary_number,
    octal,
    binary_number
    R'19' * digit^0,
  }

  special = c 'special', word {
    'NULL', 'TRUE', 'FALSE', 'null', 'true', 'false'
  }

  sq_string = c('string', span("'", "'", '\\'))
  php_start = c 'comment', P'<?' * P'php'^-1
  constant = c 'constant', word any('_', upper)^1 * any('_', upper, digit)^0
  clazz = c 'class', upper^1 * (alpha + digit + '_')^0

  string_key = sequence {
    c 'key', any {
      span("'", "'", '\\'),
      span('"', '"', '\\')
    },
    ws^0,
    #P'=>'
  }

  functions = sequence {
    c('keyword', 'function'),
    ws^1,
    c('fdecl', alpha^1)
  }

  P {
    'all'

    all: any {
      comment,
      string_key,
      V'string',
      V'heredoc',
      V'nowdoc',
      special,
      php_start,
      functions,
      operator,
      number,
      keyword,
      constant,
      clazz,
      identifier,
    }

    string: sq_string +  V'dq_string'

    dq_string: sequence {
      c('string', '"'),
      V'dq_string_chunk',
      c('string', '"'),
    }

    dq_string_chunk: c('string', scan_until(any('"', '$', '{'), '\\')) * any {
      #P('"'),
      V'interpolation' * V'dq_string_chunk',
      (c('string', 1) * V'dq_string_chunk')
    }

    interpolation: any {
      V'simple_interpolation',
      V'complex_interpolation'
    }

    simple_interpolation: sequence {
      #P'$',
      identifier,
      any({
        c('operator', '->') * identifier,
        c('operator', '[') * (number + identifier) * c('operator', ']')
      })^-1
    }

    complex_interpolation: sequence {
      c('operator', '{'),
      #P'$',
      sequence({
        -P'}',
        any {
          V'string',
          special,
          operator,
          number,
          constant,
          identifier,
          P(1),
        }
      })^1,

      c('operator', P'}'^1),
    }

    heredoc: sequence {
      V'heredoc_start'
      V'heredoc_chunk',
      V'heredoc_end'^0,
    }

    heredoc_start: sequence {
      c('operator', '<<<'),
      c('string', '"')^-1,
      c('constant', Cg(alpha^1, 'hd_del')),
      c('string', '"')^-1,
    }

    heredoc_chunk: c('string', scan_until(any(V'heredoc_end', '$', '{') , '\\')) * any {
      P(-1),
      #V'heredoc_end',
      V'interpolation' * V'heredoc_chunk',
      (c('string', 1) * V'heredoc_chunk')
    }

    heredoc_end: c('string', eol) * c('constant', match_back('hd_del'))

    nowdoc: sequence {
      V'nowdoc_start'
      c('string', scan_until(V'nowdoc_end', '\\')),
      V'nowdoc_end'^0,
    }

    nowdoc_start: sequence {
      c('operator', '<<<'),
      c('string', "'")^-1,
      c('constant', Cg(alpha^1, 'nd_del')),
      c('string', "'")^-1,
    }

    nowdoc_end: c('string', eol) * c('constant', match_back('nd_del'))

 }

embedded_php = howl.aux.lpeg_lexer ->
  embedded_php = P {
    any(V'expansion')

    expansion: sequence {
      capture('operator', P'<?' * P'php'^-1),
      sub_lex('php', '?>'),
      capture('operator', '?>')^-1
    }
  }

  compose 'html', embedded_php

:php, :embedded_php
