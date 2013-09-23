-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

howl.aux.lpeg_lexer ->

  comment = capture 'comment', span('#' * space^1, eol)
  directive = capture 'preprocessor', span('---', eol)
  delimiter = capture('special', P'...') * eol
  operator = capture 'operator', S'-:&*?!(){}[]'
  key = capture('key', alpha * (alpha + S'-_')^0) * #(space^0 * ':' * space^1)
  dq_string = capture 'string', span('"', '"', P'\\')
  sq_string = capture 'string', span("'", "'")
  string = any{ dq_string, sq_string }
  number = B(space^1) * capture('number', digit * (digit + '.')^0) * #space^1

  any {
    string,
    directive,
    delimiter,
    comment,
    key,
    number,
    operator,
  }
