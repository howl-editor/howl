-- Copyright 2012-2020 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.util.lpeg_lexer ->
  c = capture

  keyword = c 'keyword', word {
    'case', 'class', 'data', 'default', 'deriving', 'do', 'else', 'forall', 'if', 'import',
    'infixl', 'infixr', 'infix', 'instance', 'in', 'let', 'module', 'newtype',
    'of', 'then', 'type', 'where', '_', 'as', 'qualified', 'hiding'
  }

  constructor = c 'type', upper^1 * (alpha + digit + S"_'#")^0

  comment = c 'comment', any {
    span('--', eol),
    span('{-', '-}')
  }

  string = c 'string', span('"', '"', P'\\')

  normal_char = P"'" * P(1) * P"'"
  escaped_char = P"'" * (P"\\" * (alpha + digit + P"\\")^1) * P"'"
  char = c 'string', any { normal_char, escaped_char }

  operator = c 'operator', S('+-*/%=<>~&^|!(){}[]#@;:,.$?\\')

  hexadecimal =  P'0' * S'xX' * xdigit^1
  octal = P'0' * S'oO'^-1 * R'07'^1
  binary = P'0' * S'bB' * R'01'^1
  float = digit^1 * '.' * digit^1
  integer = digit^1
  number = c 'number', any { hexadecimal, octal, binary, float, integer }

  delimiter = any { space, S'/.,(){}[]^#@' }
  identifier = c 'identifier', complement(delimiter)^1

  any {
    comment,
    keyword,
    constructor,
    operator
    number,
    string,
    char,
    identifier,
  }

