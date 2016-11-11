-- Copyright 2013-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.util.lpeg_lexer ->

  comment = capture 'comment', span('#', eol)
  directive = capture 'preproc', span('---', eol)
  delimiter = capture('special', '...') * eol
  operator = capture 'operator', S'-:&*?!(){}[]'
  key = capture('key', alpha * (alnum + S'-_')^0) * #(space^0 * ':' * space^1)
  dq_string = capture 'string', span('"', '"', '\\')
  sq_string = capture 'string', span("'", "'")
  string = any{ dq_string, sq_string }
  number = B(space^1) * capture('number', digit * (digit + '.')^0) * #space^1
  block_scalars = capture 'string', S'>|' * scan_through_indented!

  any {
    string,
    directive,
    delimiter,
    comment,
    key,
    number,
    block_scalars,
    operator,
  }
