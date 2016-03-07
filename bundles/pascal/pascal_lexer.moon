howl.aux.lpeg_lexer ->
  c = capture

  id = (alpha + '_')^1 * (alpha + digit + P'_')^0
  ws = c 'whitespace', blank^0

  identifier = c 'identifier', id

  pascal_word = (words) ->
    new_words = for w in *words
      sequence [P(c\upper!) + c\lower! for c in w\gmatch '.']

    word new_words

  keyword = c 'keyword', -B'&' * pascal_word {
    'absolute', 'abstract', 'alias', 'and', 'array', 'asm', 'assembler', 'as',
    'begin', 'bitpacked', 'break', 'case', 'cdecl', 'class', 'constructor',
    'const', 'continue', 'cppdecl', 'cvar', 'default', 'deprecated', 'destructor',
    'dispinterface', 'div', 'downto', 'do', 'dynamic', 'else', 'end', 'enumerator',
    'except', 'experimental', 'exports', 'export', 'external', 'far16', 'far',
    'file', 'finalization', 'finally', 'forward', 'for', 'function', 'generic',
    'goto', 'helper', 'if', 'implementation', 'implements', 'index', 'inherited',
    'initialization', 'inline', 'interface', 'interrupt', 'in', 'iochecks', 'is',
    'label', 'library', 'local', 'message', 'mod', 'name', 'near', 'nil',
    'nodefault', 'noreturn', 'nostackframe', 'not', 'object', 'of', 'oldfpccall',
    'on', 'operator', 'or', 'otherwise', 'out', 'overload', 'override', 'packed',
    'pascal', 'platform', 'private', 'procedure', 'program', 'property',
    'protected', 'public', 'published', 'raise', 'read', 'record', 'register',
    'reintroduce', 'repeat', 'resourcestring', 'result', 'safecall',
    'saveregisters', 'self', 'set', 'shl', 'shr', 'softfloat', 'specialize',
    'static', 'stdcall', 'stored', 'strict', 'string', 'then', 'threadvar', 'to',
    'try', 'type', 'unaligned', 'unimplemented', 'unit', 'until', 'uses',
    'varargs', 'var', 'virtual', 'while', 'with', 'xor'
  }

  special = c 'special', pascal_word { 'true', 'false', 'dispose', 'exit', 'new' }

  builtin_types = pascal_word {
    'AnsiChar', 'AnsiString', 'Boolean', 'ByteBool', 'Byte', 'Cardinal', 'Char',
    'Comp', 'Currency', 'Double', 'Extended', 'Int64', 'Integer', 'LongBool',
    'Longint', 'Longword', 'QWord', 'RawByteString', 'Real', 'ShortString',
    'Shortint', 'Single', 'SmallInt', 'String', 'UCS2Char', 'UCS4Char',
    'UTF8String', 'UniCodeChar', 'UnicodeString', 'WideChar', 'WideString',
    'WordBool', 'Word'
  }

  type_name = S'TPI' * id

  types = c 'type', builtin_types + type_name

  generic = sequence {
    c 'operator', '<'
    ((V'all' + P 1) - S'<>;')^0
    c 'operator', '>'
    ws
  }

  type_def = any {
    sequence {
      c 'type_def', type_name
      ws
      generic^-1
      c 'operator', '='
    }

    sequence {
      c 'type_def', id
      ws
      generic^-1
      c 'operator', '='
      ws
      c 'keyword', pascal_word {
        'packed', 'set', 'record', 'class', 'file', 'object', 'interface'
      }
    }
  }

  fdecl = sequence {
    c 'keyword', pascal_word { 'procedure', 'function' }
    ws
    c 'fdecl', (id + '.')^1
  }

  comment_span = (start_pat, end_pat) ->
    start_pat * ((V'comment' + P 1) - end_pat)^0 * end_pat

  comment = c 'comment', P {
    'comment'

    comment: any {
      comment_span P'//', eol
      comment_span P'/*', '*/'
      comment_span P'(*', '*)'
      comment_span P'{', '}'
    }
  }

  unsigned = any {
    digit^1
    P'$' * xdigit^1
    P'&' * R'07'^1
    P'%' * S'01'^1
  }

  number = c 'number', any {
    float
    unsigned
  }

  string = c 'string', any {
    span "'", "'"
    P'#' * unsigned
  }

  operator = c 'operator', S'+-*/=<>[].,():;^@'

  P {
    'all'

    all: any {
      comment
      operator
      string
      number
      type_def
      fdecl
      keyword
      special
      types
      identifier
    }
  }
