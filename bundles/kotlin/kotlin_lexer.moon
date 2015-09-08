howl.aux.lpeg_lexer ->
  c = capture
  ident = (alpha + '_')^1 * (alpha + digit + '_')^0

  identifier = c 'identifier', ident

  keyword = c 'keyword', word {
    'abstract', 'annotation' ,'as', 'attribute', 'break', 'by', 'catch', 'class',
    'constructor', 'companion', 'continue', 'data', 'do', 'dynamic', 'else', 'enum',
    'finally', 'final', 'for', 'fun', 'if', 'get', 'import', 'init', 'inline',
    'inner', 'interface', 'internal', 'in', 'is', 'lazy', 'native', 'object',
    'open', 'out', 'override', 'package', 'private', 'protected', 'public', 'ref',
    'return', 'reified', 'sealed', 'set', 'super', 'synchronized', 'this', 'This',
    'throw', 'trait', 'transient', 'try', 'typealias', 'val', 'vararg', 'var',
    'volatile', 'when', 'where', 'while'
  }

  fundef = c('keyword', 'fun') * c('whitespace', space^1) * c('fdecl', ident)
  classdef = c('keyword', 'class') * c('whitespace', space^1) * c('type_def', ident)

  type = c 'type', word {
    'Any', 'Boolean', 'Byte', 'Char', 'Double', 'Float', 'Int', 'Long', 'Nothing',
    'Short', 'String', 'Unit'
  }

  special = c 'special', word { 'true', 'false', 'null' }

  char = span "'", "'", '\\'
  number = c 'number', any {
    float
    hexadecimal_float
    hexadecimal
    octal
    R'19' * digit^0
  }

  comment = c 'comment', any {
    P'//' * scan_until eol
    span '/*', '*/'
  }

  operator = c 'operator', S'#+-*/%^&|!:=<>()[]{},;$'

  P {
    'all'

    all: any {
      comment
      fundef
      classdef
      V'string'
      keyword
      type
      special
      identifier
      operator
      number
    }

    string: any {
      c('string', '"') * V'q_string_chunk'
      c('string', '"""') * V'tq_string_chunk'
    }

    q_interpolation: (c 'operator', P'$') * (identifier + ((-P'}' * (V'all' + 1))^1 * c('operator', '}'))) * V'q_string_chunk'
    tq_interpolation: (c 'operator', P'$') * (identifier + ((-P'}' * (V'all' + 1))^1 * c('operator', '}'))) * V'tq_string_chunk'
    --tq_interpolation: #P'$' * (-P'}' * (V'all' + 1))^1 * c('operator', '}') * V'tq_string_chunk'
    q_string_chunk: c('string', scan_to(P'"' + #(P'$' * (ident + "{")), P'\\')) * V('q_interpolation')^0
    tq_string_chunk: c('string', scan_to(P'"' + #(P'$' * (ident + "{")), P'\\')) * V('tq_interpolation')^0
    --tq_string_chunk: c('string', scan_to(P'"""' + #(P'${'), P'\\')) * V('tq_interpolation')^0
  }

  --any {
  --  comment
  --  string
  --  keyword
  --  type
  --  special
  --  identifier
  --  operator
  --  number
  --}
