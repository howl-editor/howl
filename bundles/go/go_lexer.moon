-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.aux.lpeg_lexer ->
  c = capture
  ident = (alpha + '_')^1 * (alpha + digit + '_')^0
  ws = c 'whitespace', space

  identifier = c 'identifier', ident

  keyword = c 'keyword', word {
    'break', 'case', 'chan', 'const', 'continue', 'default', 'defer', 'else',
    'fallthrough', 'for', 'func', 'go', 'goto', 'if', 'import', 'interface',
    'map', 'package', 'range', 'return', 'select', 'struct', 'switch', 'type',
    'var'
  }

  type = c 'type', word {
    'bool', 'byte', 'complex64', 'complex128', 'float32', 'float64', 'int8',
    'int16', 'int32', 'int64', 'rune', 'string', 'uint8', 'uint16', 'uint32', 'uint64',
    'complex', 'float', 'int', 'uint', 'uintptr'
  }
  
  builtin = c 'function', word {
    'append', 'cap', 'close', 'complex', 'copy', 'delete', 'imag', 'len', 'make',
    'new', 'panic', 'print', 'println', 'real', 'recover'
  }

  fdecl = sequence {
    c 'keyword', 'func'
    any {
      sequence({
        ws^0
        c 'operator', '('
        ((V'all' + P 1 + ws) - P')')^0
        c 'operator', ')'
        ws^0
      })
      ws^1
    }
    c 'fdecl', ident
  }
  
  type_def = sequence {
    c 'keyword', 'type'
    ws^1
    c 'type_def', ident
  }

  operator = c 'operator', S'+-*/%&|^<>=!:;.,()[]{}'

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

  string = c 'string', any {
    span('"', '"', '\\')
    span('`', '`', nil)
  }

  constant = c 'special', word { 'true', 'false', 'iota', 'nil' }

  P {
    'all'

    all: any {
      comment,
      string,
      fdecl,
      type_def,
      type,
      keyword,
      builtin,
      operator,
      number,
      constant,
      identifier,
    }
  }
