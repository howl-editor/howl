-- Copyright 2016-2025 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.util.lpeg_lexer ->
  c = capture
  ident = (alpha + '_')^1 * (alpha + digit + '_')^0

  -- Comments.
  line_comment = P'//' * scan_until eol
  block_comment = span '/*', '*/' -- Note: Doesn't handle nested block comments correctly yet
  comment = c 'comment', any {line_comment, block_comment}

  hex_digit = R'09' + R'af' + R'AF' + '_'
  binary_digit = S'01' + '_'
  octal_digit = R'07' + '_'
  decimal_digit = digit + '_'

  -- Strings & Chars.
  escape_seq = '\\' * (S'ntr"\\\'0' + P'x' * hex_digit * hex_digit + P'u{' * hex_digit^1 * P'}') -- Corrected escaping and P usage
  dq_str_content = (escape_seq + P(1) - '"' - '\\')^0
  dq_str = '"' * dq_str_content * '"'

  raw_str_start = P'r'^0 * Cg(P'#'^0, 'lvl') * '"'
  raw_str_end = '"' * match_back 'lvl'
  raw_str = raw_str_start * scan_to raw_str_end

  char_content = escape_seq + (P(1) - '\'' - '\\')
  char = P"'" * char_content * P"'"

  byte_dq_str_content = (escape_seq + P(1) - '"' - '\\')^0
  byte_dq_str = P'b"' * byte_dq_str_content * '"'

  byte_raw_str_start = P'br'^0 * Cg(P'#'^0, 'lvl') * '"'
  byte_raw_str_end = '"' * match_back 'lvl'
  byte_raw_str = byte_raw_str_start * scan_to byte_raw_str_end

  byte_char_content = escape_seq + (P(1) - '\'' - '\\')
  byte_char = P"b'" * byte_char_content * P"'"

  string = c 'string', any {byte_raw_str, raw_str, byte_dq_str, dq_str, byte_char, char}

  -- Numbers.
  integer_suffix = (S'iu' * S'8' + S'16' + S'32' + S'64' + S'128' + P'size')^-1
  float_suffix = (P'f32' + P'f64')^-1

  binary = P'0b' * binary_digit^1 * integer_suffix
  octal = P'0o' * octal_digit^1 * integer_suffix
  hex = P'0x' * hex_digit^1 * integer_suffix
  decimal = decimal_digit^1 * integer_suffix

  float_exp = S'eE' * S'+-'^-1 * decimal_digit^1
  float_lit = (decimal_digit^1 * '.' * decimal_digit^0 + '.' * decimal_digit^1 + decimal_digit^1) * float_exp^-1
  floats = float_lit * float_suffix

  number = c 'number', any {
    hex,
    binary,
    octal,
    floats,
    decimal, -- Decimal integer must be last to avoid matching prefixes of floats
  }

  -- Keywords.
  keyword = c 'keyword', word {
    'as', 'async', 'await', 'box', 'break', 'const', 'continue', 'crate',
    'dyn', 'else', 'enum', 'extern', 'fn', 'for', 'if', 'impl',
    'in', 'let', 'loop', 'match', 'mod', 'move', 'mut', 'pub', 'ref',
    'return', 'static', 'struct', 'super', 'trait', 'type', 'union', 'unsafe',
    'use', 'where', 'while'
    -- 'abstract', 'alignof', 'become', 'do', 'final', 'macro',
    -- 'offsetof', 'override', 'priv', 'proc', 'pure', 'sizeof',
    -- 'typeof', 'unsized', 'virtual', 'yield' -- Removed older/unused keywords
  }
  -- Special words
  special = c 'special', word { 'true', 'false', 'self' }

  -- Type/Trait/Module/Function declarations
  def_item = sequence {
    c 'keyword', word { 'mod', 'struct', 'enum', 'trait', 'type', 'union' }
    c 'whitespace', space^1
    c 'type_def', ident
  }

  fdecl = sequence {
    c 'keyword', 'fn'
    c 'whitespace', space^1
    c 'fdecl', ident
  }

  -- Primitive Types.
  primitive = word {
    'bool', 'isize', 'usize', 'char', 'str',
    'u8', 'u16', 'u32', 'u64', 'u128',
    'i8', 'i16', 'i32', 'i64', 'i128',
    'f32','f64',
  }

  -- Library Types.
  library = upper^1 * (alpha + digit + '_')^0

  -- Lifetimes.
  lifetime = "'" * (ident + P'static') -- Allow 'static
  type = c 'type', any {lifetime, primitive}
  type_library = c 'constant', library

  -- Identifiers.
  identifier = c 'identifier', ident

  -- Operators.
  -- Order matters: longest matches first
  operator = c 'operator', any {
    '::', '->', '=>', '..', '..=',
    '==', '!=', '>=', '<=',
    '&&', '||',
    '<<', '>>',
    '+=', '-=', '*=', '/=', '%=', '&=', '|=', '^=', '<<=', '>>=',
    S'+-/*%<>!=^&|?:;,.()[]{}@#~$'
  }

  -- Attributes.
  attribute = c 'preproc', (span (P'#![' + P'#['), P']')

  -- Syntax extensions (macros).
  extension = c 'special', any {ident * S'!'}

  P {
    'all'

    all: any {
      comment,
      attribute,
      def_item,
      fdecl,
      special,
      keyword,
      extension,
      string,
      type_library,
      type,
      number,
      operator,
      identifier,
    }
  }

