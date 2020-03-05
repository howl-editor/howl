-- Copyright 2020 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.util.lpeg_lexer ->
  c = capture

  -- Shorthand for lexer.word
  ident = (alpha + '_')^1 * (alpha + digit + '_')^0

  -- Comments
  line_comment = P'//' * scan_until eol
  comment = c 'comment', line_comment

  -- Hex digits
  hex_digit = R'09' + R'af' + R'AF'

  -- Strings
  dq_str = span '"', '"', '\\'
  cont = R'\128\191'
  utf8 = R'\0\127' + R'\194\223' * cont + R'\224\239' * cont * cont + R'\240\244' * cont * cont * cont
  ascii_esc = '\\' * S'trn\'"\\0'
  unicode_esc = ('\\u{' * hex_digit^1 * '}')
  hex_esc = ('\\x' * hex_digit^1)
  char = P"'" * (unicode_esc + hex_esc + ascii_esc + utf8) * P"'"
  string  = c 'string', any {dq_str, char}

  -- Multi-line strings
  multi_span = P'\\\\' * scan_until eol
  multi_string = c 'string', multi_span

  -- Numbers
  binary = P'0b' * S'01'^1
  oct = P'0o' * S'01234567'^1
  hex = P'0x' * hex_digit^1
  decimal = digit^1
  floats = float * (S'eE' * S'+-'^-1 * decimal)^-1
  number = c 'number', any {
    binary,
    hex,
    oct,
    decimal,
    floats
  }

  -- Keywords
  keyword = c 'keyword', word {
    'align', 'allowzero', 'and', 'anyframe', 'asm', 'async', 'await', 'break',
    'callconv', 'catch', 'comptime', 'const', 'continue', 'defer', 'else',
    'enum', 'errdefer', 'error', 'export', 'extern', 'fn', 'for', 'if',
    'inline', 'noalias', 'orelse', 'or', 'packed', 'promise', 'pub', 'resume',
    'return', 'linksection', 'struct', 'suspend', 'switch', 'test',
    'threadlocal', 'try', 'union', 'unreachable', 'usingnamespace', 'var',
    'volatile', 'while'
  }

  -- Special words
  special = c 'special', word {
      'true', 'false', 'null', 'undefined'
  }

  -- Builtin functions
  builtin = c 'function', word {
      '@addWithOverflow', '@alignCast', '@alignOf', '@as', '@asyncCall',
      '@atomicLoad', '@atomicRmw', '@atomicStore', '@bitCast', '@bitOffsetOf',
      '@bitReverse', '@bitSizeOf', '@boolToInt', '@breakpoint', '@byteOffsetOf',
      '@byteSwap', '@call', '@cDefine', '@ceil', '@cImport', '@cInclude', '@clz',
      '@cmpxchgStrong', '@cmpxchgWeak', '@compileError', '@compileLog', '@cos',
      '@ctz', '@cUndef', '@divExact', '@divFloor', '@divTrunc', '@embedFile',
      '@enumToInt', '@errorName', '@errorReturnTrace', '@errorToInt',
      '@errSetCast', '@exp2', '@export', '@exp', '@fabs', '@fence',
      '@fieldParentPtr', '@field', '@floatCast', '@floatToInt', '@floor',
      '@frameAddress', '@frameSize', '@frame', '@Frame', '@hasDecl',
      '@hasField', '@import', '@intCast', '@intToEnum', '@intToError',
      '@intToFloat', '@intToPtr', '@log10', '@log2', '@log', '@memcpy',
      '@memset', '@mod', '@mulAdd', '@mulWithOverflow', '@OpaqueType',
      '@panic', '@popCount', '@ptrCast', '@ptrToInt', '@rem', '@returnAddress',
      '@round', '@setAlignStack', '@setCold', '@setEvalBranchQuota',
      '@setFloatMode', '@setRuntimeSafety', '@shlExact', '@shlWithOverflow',
      '@shrExact', '@shuffle', '@sin', '@sizeOf', '@splat', '@sqrt',
      '@subWithOverflow', '@tagName', '@TagType', '@This', '@truncate',
      '@trunc', '@typeInfo', '@typeName', '@TypeOf', '@Type', '@unionInit',
      '@Vector'
  }

  -- Record definitions
  struct_def = sequence {
    c 'keyword', word { 'struct', 'enum', 'error', 'union' }
    c 'whitespace', space^1
    c 'type_def', ident
  }

  -- Function declarations
  fdecl = sequence {
    c 'keyword', 'fn'
    c 'whitespace', space^1
    c 'fdecl', ident
  }

  -- Primitive types
  primitive = word {
    'anyerror', 'bool', 'c_int', 'c_longdouble', 'c_longlong', 'c_long',
    'comptime_float', 'comptime_int', 'c_short', 'c_uint', 'c_ulonglong',
    'c_ulong', 'c_ushort', 'c_void', 'f128', 'f16', 'f32', 'f64', 'isize',
    'noreturn', 'type', 'usize', 'void'
  }
  type = c 'type', any {primitive}
  integer = P'i' * digit^1
  integer_type = c 'type', integer
  unsigned = P'u' * digit^1
  unsigned_type = c 'type', unsigned

  -- Types, library modules and constants
  important = upper^1 * (upper + lower + digit + '_')^0
  important_name = c 'constant', important

  -- Identifiers
  identifier = c 'identifier', ident

  -- Operators
  operator = c 'operator', S'+=%-*/<>&|^~?!:;,.()[]{}'

  any {
    comment,
    string,
    multi_string,
    number,
    keyword,
    special,
    builtin,
    struct_def,
    fdecl,
    type,
    integer_type,
    unsigned_type,
    important_name,
    identifier,
    operator
  }
