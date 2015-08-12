
howl.aux.lpeg_lexer ->
  c = capture

  nim_identifier = (identifier) ->
    word_char = alpha + '_' + digit
    grammar = (-B(1) + B(-word_char)) * P(identifier\usub(1, 1))
    for char in *identifier\usub(2)
      grammar *= P'_'^-1
      grammar *= (P(char.ulower) + P(char.uupper))
    return grammar * #-word_char

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

  comment = c 'comment', P'#' * scan_until(eol)
  operator = c 'operator', S'=+-*/<>@$~&%|!?^.:\\[]{}(),'
  ident = (alpha + '_')^1 * (alpha + digit + S'_')^0
  backquoted_name = span('`', '`')

  identifier = c 'identifier', ident

  proc_fdecl = c('keyword', 'proc') * c('whitespace', space^1) * c('fdecl', any {ident,  backquoted_name}) * P'*'^-1
  iterator_fdecl = c('keyword', 'iterator') * c('whitespace', space^1) * c('fdecl', ident) * P'*'^-1
  method_fdecl = c('keyword', 'method') * c('whitespace', space^1) * c('fdecl', ident) * P'*'^-1

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
  -- number = integer
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
      operator,
      iterator_fdecl,
      proc_fdecl,
      method_fdecl,
      keyword,
      identifier
    }

    string: any {
      capture 'string', any { string, tq_string }
    }
  }
