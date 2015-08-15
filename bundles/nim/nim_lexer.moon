-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.aux.lpeg_lexer ->
  c = capture

  nim_identifier = (identifier) ->
    word_char = alpha + '_' + digit
    pattern = (-B(1) + B(-word_char)) * P(identifier\usub(1, 1))
    for char in *identifier\usub(2)
      pattern *= P'_'^-1
      pattern *= (P(char.ulower) + P(char.uupper))
    return pattern * #-word_char

  keywords = {
    'addr', 'and', 'as', 'asm', 'atomic', 'bind', 'block', 'break', 'case',
    'cast', 'concept', 'const', 'continue', 'converter', 'defer', 'discard',
    'distinct', 'div', 'do', 'elif', 'else', 'end', 'enum', 'except', 'export',
    'finally', 'for', 'from', 'func', 'if', 'import', 'in',
    'include', 'interface', 'is', 'isnot', 'iterator', 'let', 'macro',
    'method', 'mixin', 'mod', 'nil', 'not', 'notin', 'object', 'of', 'or',
    'out', 'proc', 'ptr', 'raise', 'ref', 'return', 'shl', 'shr', 'static',
    'template', 'try', 'tuple', 'type', 'using', 'var', 'when', 'while',
    'with', 'without', 'xor', 'yield',
  }

  keyword = c 'keyword', -B'.' * any [nim_identifier(keyword) for keyword in *keywords]

  builtin_types = {
  "int",
  "int8",
  "int16",
  "int32",
  "int64",
  "uint",
  "uint8",
  "uint16",
  "uint32",
  "uint64",
  "float",
  "float32",
  "float64",
  "bool",
  "char",
  "string",
  "cstring",
  "pointer",
  "expr",
  "stmt",
  "typedesc",
  "void",
  "auto",
  "any",
  "untyped",
  "typed",
  "range",
  "array",
  "openArray",
  "varargs",
  "seq",
  "set",
  "byte",
  "clong",
  "culong",
  "cchar",
  "cschar",
  "cshort",
  "cint",
  "csize",
  "clonglong",
  "cfloat",
  "cdouble",
  "clongdouble",
  "cuchar",
  "cushort",
  "cuint",
  "culonglong",
  "cstringArray",
  }

  builtin = c 'class', -B'.' * any [nim_identifier(type_name) for type_name in *builtin_types]

  comment = c 'comment', P'#' * scan_until(eol)
  operator = c 'operator', S'=+-*/<>@$~&%|!?^.:\\[]{}(),'
  ident = (alpha + '_')^1 * (alpha + digit + S'_')^0
  backquoted_name = span('`', '`')

  identifier = c 'identifier', ident

  function_name = c('whitespace', space^1) * c('fdecl', any {ident,  backquoted_name})
  function_export_marker = c('whitespace', space^0) * c('special', P'*'^-1)
  proc_fdecl = c('keyword', nim_identifier('proc')) * function_name * function_export_marker
  iterator_fdecl = c('keyword', nim_identifier('iterator')) * function_name * function_export_marker
  method_fdecl = c('keyword', nim_identifier('method')) * function_name * function_export_marker
  template_fdecl = c('keyword', nim_identifier('template')) * function_name * function_export_marker
  macro_fdecl = c('keyword', nim_identifier('macro')) * function_name * function_export_marker

  type_name = c 'class', upper^1 * (alpha + digit + '_')^0
  backquoted_type_name = c 'class', P'`' * type_name * P'`'
  -- backquoted_type_name = c 'class', P'`' * type_name * P'`'

  pragma = c 'preproc', span('{.', '}')

  hex_digit_run = xdigit^1 * (P'_' * xdigit^1)^0
  hexadecimal_number =  P'0' * S'xX' * hex_digit_run

  oct_digit_run = R'07'^1 * (P'_' * R'07'^1)^0
  octal_number = P'0' * S'oO'^-1 * oct_digit_run

  binary_digit_run = S'01'^1 * (P'_' * S'01'^1)^0
  binary_number = P'0' * S'bB' * binary_digit_run

  digit_run = digit^1 * (P'_' * digit^1)^0
  simple_number = digit_run

  number_with_point = digit_run * '.' * digit_run

  integer_size_suffix =  c 'special', P"'" * (P'i' + P'u') * any {'8', '16', '32', '64'}
  float_size_suffix =  c 'special', P"'" * P'f' * any {'32', '64'}
  exponent_suffix = c('special', S'eE') * c('number', S('-+')^-1 * digit_run)

  integer = c 'number', any {
   octal_number
   hexadecimal_number
   binary_number
   simple_number
  }

  number = c('number', simple_number) * exponent_suffix * (float_size_suffix^-1)
  number += c('number', number_with_point) * (exponent_suffix^-1) * (float_size_suffix^-1)
  number += (integer * integer_size_suffix^-1)
  number *= #-(alpha + digit + S'_') -- no alphanum should be attached to the number
  string = span('"', '"', '\\')
  tq_string = span('"""', '"""', '\\')

  char = c 'char', B(-digit) * span('\'', '\'', '\\')

  P {
    'all'
    all: any {
      number,
      V'string',
      char,
      pragma,
      comment,
      iterator_fdecl,
      proc_fdecl,
      method_fdecl,
      template_fdecl,
      macro_fdecl,
      keyword,
      builtin,
      type_name,
      backquoted_type_name,
      identifier,
      operator,
    }

    string: any {
      capture 'string', any { tq_string, string }
    }
  }
