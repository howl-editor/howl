-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

cur_line_indent = (subject, pos) ->
  ws = 0
  for i = pos, 1, -1
    c = subject[i]
    if c\match '[\n\r]+' then return ws
    elseif c\match '%s+' then  ws += 1
    else ws = 0
  ws

block_scalar_end = (subject, pos) ->
  cur_indent = cur_line_indent subject, pos - 1
  _, block_end = subject\ufind r"\\R\\s{0,#{cur_indent}}\\S", pos + 1
  block_end and block_end or #subject + 1

howl.aux.lpeg_lexer ->

  comment = capture 'comment', span('#' * space^1, eol)
  directive = capture 'preprocessor', span('---', eol)
  delimiter = capture('special', '...') * eol
  operator = capture 'operator', S'-:&*?!(){}[]'
  key = capture('key', alpha * (alpha + S'-_')^0) * #(space^0 * ':' * space^1)
  dq_string = capture 'string', span('"', '"', '\\')
  sq_string = capture 'string', span("'", "'")
  string = any{ dq_string, sq_string }
  number = B(space^1) * capture('number', digit * (digit + '.')^0) * #space^1
  block_scalars = capture 'string', Cmt(S'>|', block_scalar_end)

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
