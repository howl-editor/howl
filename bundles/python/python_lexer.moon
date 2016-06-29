-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.aux.lpeg_lexer ->
  c = capture

  keyword = c 'keyword', -B'.' * word {
    "and", "assert", "async", "as", "await",
    "break", "class", "continue", "def", "del", "elif",
    "else", "except", "exec", "finally", "for", "from", "global", "if", "import",
    "in", "is", "lambda", "not", "or", "pass", "print", "raise", "return", "try",
    "while", "with", "yield"
  }

  functions = c 'function', -B'.' * word {
    "abs", "all", "any", "apply", "basestring", "bin",
    "bool", "buffer", "bytearray", "bytes", "callable", "chr", "classmethod", "cmp",
    "coerce", "compile", "complex", "copyright", "credits", "delattr", "dict",
    "dir", "divmod", "enumerate", "eval", "execfile", "exit", "file", "filter",
    "float", "format", "frozenset", "getattr", "globals", "hasattr", "hash", "help",
    "hex", "id", "input", "intern", "int", "isinstance", "issubclass", "iter",
    "len", "license", "list", "locals", "long", "map", "max", "memoryview", "min",
    "next", "object", "oct", "open", "ord", "pow", "property", "quit",
    "range", "raw_input", "reduce", "reload", "repr", "reversed", "round", "setattr",
    "set", "slice", "sorted", "staticmethod", "str", "sum", "super", "tuple",
    "type", "unichr", "unicode", "vars", "xrange", "zip"
    }

  constant = c 'constant', word {
    'ArithmeticError', 'AssertionError', 'AttributeError', 'BaseException',
    'BufferError', 'BytesWarning',
    'DeprecationWarning', 'EOFError', 'Ellipsis', 'EnvironmentError', 'Exception',
    'False', 'FloatingPointError', 'FutureWarning', 'GeneratorExit', 'IOError',
    'ImportError', 'ImportWarning', 'IndentationError', 'IndexError', 'KeyError',
    'KeyboardInterrupt', 'LookupError', 'MemoryError', 'NameError', 'None',
    'NotImplementedError', 'NotImplemented', 'OSError', 'OverflowError',
    'PendingDeprecationWarning', 'ReferenceError', 'RuntimeError',
    'RuntimeWarning', 'StandardError', 'StopIteration', 'SyntaxError',
    'SyntaxWarning', 'SystemError', 'SystemExit', 'TabError', 'True', 'TypeError',
    'UnboundLocalError', 'UnicodeDecodeError', 'UnicodeEncodeError',
    'UnicodeError', 'UnicodeTranslateError', 'UnicodeWarning', 'UserWarning',
    'ValueError', 'Warning', 'ZeroDivisionError'
  }

  comment = c 'comment', P'#' * scan_until(eol)
  operator = c 'operator', S'+-*/%~&^=!<>;:,.(){}[]|`'

  name = (alpha + '_')^1 * (alpha + digit + P'_')^0
  user_defined_constant = c('constant', (upper + '_')^1) * -#(alpha + digit)

  dunder_identifier = c 'special', (P'__' * (alpha^1 * (alpha + digit)^0) * P'__')

  identifier = c 'identifier', name
  fdecl = c('keyword', 'def') * c('whitespace', space^1) * c('fdecl', name)
  classdef = c('keyword', 'class') * c('whitespace', space^1) * c('type_def', name)
  self = c 'member', word {'self'}
  member = self * c('operator', '.') * c('member', name)

  hexadecimal =  P'0' * S'xX' * xdigit^1
  octal = P'0' * S'oO'^-1 * R'07'^1
  binary = P'0' * S'bB' * R'01'^1

  digit_run = digit^1
  float = digit_run * '.' * digit_run
  integer = digit_run

  basic_number = c 'number', any { hexadecimal, octal, binary, float, integer }

  long_integer = c('number', digit_run) * c('special', S'lL')
  exponent_float = c('number', any { float, integer }) * c('special', S'eE') * c('number', S'+-'^-1 * integer)
  complex = c('number', any { exponent_float, float, integer }) * c('special', S'jJ')

  number = any { complex, exponent_float, long_integer, basic_number }

  basic_string = c 'string', any {
    span('"""', '"""', '\\'),
    span("'''", "'''", '\\')
    span('"', '"', '\\'),
    span("'", "'", '\\'),
  }

  raw_string = c('special', S'rR') * basic_string
  encoded_string = c('special', S'bBuU') * any { raw_string, basic_string }

  f_prefix = c 'special', any {
    S'rR' * S'fF'
    S'fF' * S'rR'
    S'fF'
  }

  format_conv = c('operator', P'!') * c('special', S'sra')
  format_part = any {
    c 'number', integer
    c('operator', P'{') * ((V'all' + space + P 1) - P'}')^0 * c('operator', P'}')
    c 'special', (P 1) - S'{}'
  }
  format_spec = c('operator', ':') * format_part^0

  f_string = sequence {
    f_prefix
    c 'string', Cg any({ "'''", '"""', "'", '"' }), 'quote'
    V'f_string_chunk'
  }

  string = any { basic_string, raw_string, encoded_string, f_string }

  decorator = c 'preproc', P'@' * name * ('.' * name)^0

  P {
    'all'

    all: any {
      string,
      comment,
      number,
      operator,
      fdecl,
      classdef,
      keyword,
      functions,
      constant,
      dunder_identifier,
      user_defined_constant,
      member,
      self,
      identifier,
      decorator
    }

    f_string_interpolation: sequence {
      ((V'all' + space + P 1) - (S'}:' + format_conv))^0
      format_conv^-1
      format_spec^-1
      c 'operator', '}'
      V'f_string_chunk'
    }

    f_string_chunk: sequence {
      c 'string', scan_to match_back'quote' + #P'{', P'\\'
      V'f_string_interpolation'^0
    }
  }
