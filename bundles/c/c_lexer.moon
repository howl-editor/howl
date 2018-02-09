-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.util.lpeg_lexer ->
  c = capture
  ident = (alpha + '_')^1 * (alpha + digit + '_')^0
  ws = c 'whitespace', S(' \t\r\n')
  continuation_ws = c 'continue', S(' \t\r\n')
  combining_ws = c 'combiner', S(' \t\r\n')^1

  identifer = c 'identifer', ident

  keyword = c 'keyword', word {
    -- C++ keywords: todo, break out into separate mode later
    'alignas', 'alignof', 'and_eq', 'and', 'asm', 'bitand', 'bitor',
    'catch', 'class', 'compl', 'constexpr',
    'const_cast', 'decltype', 'delete', 'dynamic_cast', 'explicit', 'export',
    'friend', 'final', 'mutable', 'namespace', 'new', 'noexcept', 'not_eq',
    'not', 'nullptr', 'operator', 'or_eq', 'or', 'private', 'protected',
    'public', 'reinterpret_cast', 'static_assert', 'static_cast', 'template',
    'this', 'thread_local', 'throw', 'try', 'typeid', 'typename',
    'union', 'using', 'virtual', 'while', 'xor_eq', 'xor'

    'auto', 'break', 'case', '_Complex', 'const', 'continue', 'default', 'do',
    'else', 'enum', 'extern', 'for', 'goto', 'if', '_Imaginary', 'inline',
    'register', 'restrict', 'return', 'signed', 'sizeof', 'static', 'struct',
    'switch', 'typedef', 'union', 'volatile', 'while'
  }

  type = c 'type', word {
    'bool', 'char16_t', 'char32_t', 'char', '_Bool', 'double', 'float', 'int',
    'long', 'short', 'unsigned', 'void', 'wchar_t'
  }

  attribute_spec = sequence {
    c 'operator', '[['
    c 'special', scan_until ']]'
    c 'operator', ']]'
    ws^0
  }

  classdef = any {
    sequence {
      c('keyword', word { 'enum', 'union' })
      combining_ws,
      c('type_def', ident)
      continuation_ws^0
      any {
        P(-1),
        c('operator', '{')
      }
    }
    sequence {
      c('keyword', word { 'class', 'struct' })
      combining_ws,
      attribute_spec^0
      c('type_def', ident) * (c('operator', P'::') + c('type_def', ident))^0
      continuation_ws^0
      any {
        P(-1),
        c('operator', S':{<'),
        c('keyword', any({'virtual', 'final'}))
      }
    }
  }

  unfinished = sequence {
    c('keyword', word { 'class', 'struct', 'enum', 'union'}),
    combining_ws,
    P(-1)
  }

  operator = c 'operator', S'+-*/%=<>~&^|!(){}[];.,?:'

  comment = c 'comment', any {
    P'//' * scan_until eol,
    span '/*', '*/'
  }

  char_constant = span("'", "'", '\\')

  number = c 'number', any {
    char_constant,
    float,
    hexadecimal_float,
    hexadecimal,
    octal,
    R'19' * digit^0,
  }

  special = c 'special', word {
    'NULL', 'TRUE', 'FALSE', '__FILE__',
    '__LINE__', '__DATE__', '__TIME__', '__TIMESTAMP__',
    'true', 'false'
  }

  string = c 'string', span('"', '"', '\\')

  preproc = c 'preproc', '#' * complement(space)^1

  include_stmt = sequence {
    c('preproc', '#include'),
    ws^0,
    c('operator', '<'),
    c('string', complement('>')^1),
    c('operator', '>'),
  }

  constant = c 'constant', word any('_', upper)^1 * any('_', upper, digit)^0

  P {
    'all'

    all: any {
      include_stmt,
      preproc,
      comment,
      string,
      unfinished,
      classdef,
      type,
      keyword,
      special,
      operator,
      number,
      constant,
      identifer,
    }
  }
