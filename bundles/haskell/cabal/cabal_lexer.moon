-- Copyright 2012-2020 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.util.lpeg_lexer ->
  c = capture

  keyword = c 'keyword', word { 'if', 'else' }

  comment = c 'comment', span('--', eol)
  operator = c 'operator', S'/.%^#,(){}[]+-=><&|!'
  dq_string = c 'string', span('"', '"', P'\\')
  sq_string = c 'string', span("'", "'", '\\')
  string = any(dq_string, sq_string)
  number = c 'number', digit^1 * alpha^-1

  delimiter = any { space, S'/.,(){}[]^#' }
  name = complement(delimiter)^1
  identifier = c 'identifier', name

  section = c 'keyword', line_start * name
  label = c 'type', (alpha + '-')^1 * (P':' * space^1)

  any {
    comment,
    label,
    section,
    keyword,
    operator
    number,
    string,
    identifier,
  }
