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

  type = c 'type', word {
    'Any', 'Boolean', 'Byte', 'Char', 'Double', 'Float', 'Int', 'Long', 'Nothing',
    'Short', 'String', 'Unit'
  }

  special = c 'special', word { 'true', 'false', 'null' }

  string = c 'string', any {
    span '"', '"', '\\'
    span '"""', '"""', '\\'
  }

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

  any {
    comment
    string
    keyword
    type
    special
    identifier
    operator
    number
  }
