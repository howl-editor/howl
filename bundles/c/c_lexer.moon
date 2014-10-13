-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

howl.aux.lpeg_lexer ->
  c = capture
  ident = (alpha + '_')^1 * (alpha + digit + '_')^0
  ws = c 'whitespace', blank

  identifer = c 'identifer', ident

  keyword = c 'keyword', word {
    'auto', '_Bool', 'break', 'case', 'char', '_Complex', 'const', 'continue',
    'default', 'double', 'do', 'else', 'enum', 'extern', 'float', 'for', 'goto',
    'if', '_Imaginary', 'inline', 'int', 'long', 'register', 'restrict',
    'return', 'short', 'signed', 'sizeof', 'static', 'struct', 'switch',
    'typedef', 'union', 'unsigned', 'void', 'volatile', 'while'

    -- C++ keywords: todo, break out into separate mode later
    'alignas', 'alignof', 'and', 'and_eq', 'asm', 'bitand', 'bitor', 'bool',
    'catch', 'char', 'char16_t', 'char32_t', 'class', 'compl', 'constexpr',
    'const_cast', 'decltype', 'delete', 'dynamic_cast', 'explicit', 'export',
    'false', 'friend', 'mutable', 'namespace', 'new', 'noexcept', 'not',
    'not_eq', 'nullptr', 'operator', 'or', 'or_eq', 'private', 'protected',
    'public', 'reinterpret_cast', 'static_assert', 'static_cast', 'template',
    'this', 'thread_local', 'throw', 'true', 'try', 'typeid', 'typename',
    'union', 'using', 'virtual', 'wchar_t', 'while', 'xor', 'xor_eq',
  }

  operator = c 'operator', S('+-*/%=<>~&^|!(){}[];.')^1

  comment = c 'comment', any {
    P'//' * scan_until eol,
    span '/*', '*/'
  }

  char_constant = P"'" * any({
    "\\" * any {
      R('07') * R('07') * R('07'),
      'x' * xdigit * xdigit,
      "'"
    },
    1
  }) * "'"

  number = c 'number', any {
    char_constant,
    float,
    hexadecimal_float,
    hexadecimal,
    octal,
    R'19' * digit^0,
  }

  special = c 'special', word {
    'NULL', 'TRUE', 'FALSE', '__FILE__',
    '__LINE__', '__DATE__', '__TIME__', '__TIMESTAMP__'
  }

  string = c 'string', span('"', '"', '\\')

  preproc = c 'preproc', '#' * complement(space)^1

  include_stmt = sequence {
    c('preproc', '#include'),
    ws^1,
    c('operator', '<'),
    c('string', complement('>')^1),
    c('operator', '>'),
  }

  constant = c 'constant', word any('_', upper)^1 * any('_', upper, digit)^0

  any {
    include_stmt,
    preproc,
    comment,
    string,
    keyword,
    special,
    operator,
    number,
    constant,
    identifer,
  }
