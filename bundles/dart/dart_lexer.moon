-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.util.lpeg_lexer ->
  c = capture
  ident = (alpha + '_')^1 * (alpha + digit + '_')^0
  ws = c 'whitespace', blank

  identifer = c 'identifer', ident

  keyword = c 'keyword', word {
    'assert', 'async', 'async*', 'await', 'break', 'case', 'catch', 'class',
    'const', 'continue', 'default', 'do', 'else', 'enum', 'extends', 'false',
    'final', 'finally', 'for', 'if', 'implements', 'import', 'in', 'is', 'new',
    'null', 'on', 'rethrow', 'return', 'super', 'switch', 'sync*', 'this', 'throw',
    'true', 'try',  'var', 'while', 'with', 'yield', 'yield*'
}

  built_in_type = any {
    c('type',
      word {
        'num', 'int', 'double', 'String'
      }
    ),
    c('keyword', word { 'void' })
  }

  operator = c 'operator', S'+-*/%=<>&^|!(){}[];'

  comment = c 'comment', any {
    P'//' * scan_until eol,
  }

  number = c 'number', any {
    float,
    hexadecimal,
    digit^1,
    word('Nan', 'Infinity')
  }

  special = c 'special', word {
    'abstract', 'as', 'covariant', 'deferred', 'dynamic',  'export', 'external',
    'factory', 'get',  'library', 'operator', 'part', 'set',
    'static', 'typedef',
    'true', 'false'}

  str = any {
    span('"', '"', '\\')
    span("'", "'", '\\')
  }
  string = c 'string', str
  raw_string = c('special', P'r') * string

  symbol = c('special', P'#' * ident)

  typename = upper^1 * (alpha + digit + '_')^0
  type = c 'type', typename
  generic_type = c 'type', P'<' * typename * '>'
  named_param = c 'key', ident * ':'

  fdecl = sequence {
      any {type, built_in_type},
      ws^1,
      c('fdecl', ident - keyword),
      ws^0,
      c('operator', '(')
  }

  classdef = c('keyword', 'class') * ws^1 * c('type_def', ident)

  annotation = c 'preproc', P'@' * ident * ('.' * ident)^0

  any {
    comment,
    named_param,
    raw_string,
    string,
    annotation,
    symbol,
    classdef,
    keyword,
    fdecl,
    special,
    generic_type,
    operator,
    number,
    built_in_type,
    type,
    identifer,
  }
