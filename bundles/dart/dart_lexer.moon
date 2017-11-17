-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.util.lpeg_lexer ->
  c = capture
  ident = (alpha + S'_$')^1 * (alpha + digit + S'_$')^0
  ws = c 'whitespace', blank

  identifier = c 'identifier', ident

  keyword = c 'keyword', word {
    'assert', 'async*', 'async', 'await', 'break', 'case', 'catch', 'class',
    'const', 'continue', 'default', 'do', 'else', 'enum', 'export', 'extends', 'final',
    'finally', 'for', 'if', 'implements', 'import', 'in', 'is', 'new', 'on', 'rethrow',
    'return', 'super', 'switch', 'sync*', 'this', 'throw', 'try',  'var', 'while', 'with',
    'yield*', 'yield'
  }

  operator = c 'operator', S'+-*/%=<>&^|!(){}[]:?;.,~'

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

  special = c 'special', word {
    'abstract', 'as', 'covariant', 'deferred', 'external', 'factory', 'get', 'hide',
    'library', 'null', 'operator', 'part', 'set', 'static', 'show', 'typedef',
    'true', 'false'
  }

  raw_multiline_str = any {
    span("'''", "'''", '\\')
    span('"""', '"""', '\\')
  }
  raw_str = any {
    span("'", "'", '\\')
    span('"', '"', '\\')
  }
  raw_string = c('special', P'r') * c('string', raw_multiline_str + raw_str)

  symbol = c('special', P'#' * ident)

  typename = any {
    sequence {
      (ident * '.')^0 -- prefix modules, e.g. html.Element
      P'_'^-1 -- leading underscore
      upper^1
      (alpha + digit + '$_')^0
    }
    word { 'num', 'int', 'double', 'bool', 'dynamic', 'void', 'String' }
  }

  basic_type = c 'type', typename
  generic_type = sequence {
    c 'type', typename
    c 'operator', '<'
    V'type'
    ws^0
    sequence({
      c 'operator', ','
      ws^0
      V'type'
      ws^0
    })^0
    c 'operator', P'>'
  }
  named_param = c 'key', -B'.' * ident * ':'

  fdecl = sequence {
      V'type'
      ws^1
      c('fdecl', ident - keyword)
      ws^0
      c('operator', '(')
  }

  classdef = c('keyword', 'class') * ws^1 * c('type_def', ident)

  annotation = c 'preproc', P'@' * ident * ('.' * ident)^0

  P {
    'all'

    all: any {
      comment,
      named_param,
      raw_string,
      V'string',
      annotation,
      symbol,
      classdef,
      keyword,
      fdecl,
      V'type',
      special,
      operator,
      number,
      identifier,
    }

    type: generic_type + basic_type

    interpolation: sequence {
      c 'operator', '$'
      any {
        identifier
        sequence {
          c 'operator', '{'
          (-P'}' * (c('string', blank + eol) + V'all' + 1))^1
          c 'operator', '}'
        }
      }
    }

    string_chunk: sequence {
      c 'string', scan_until_capture 'quote', '\\', '$'
      any {
        c 'string', match_back 'quote'
        P(-1)
        sequence {
          any {
            V'interpolation' -- interpolation
            c 'string', P 1 -- pass through
          }
          V'string_chunk'
        }
      }
    }

    string: sequence {
      c 'string', Cg any({"'''", '"""', "'", '"'}), 'quote'
      V'string_chunk'
    }
  }
