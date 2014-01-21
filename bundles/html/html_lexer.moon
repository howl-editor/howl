-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

import style from howl.ui

style.define 'html_tag', 'keyword'
style.define 'html_attr', 'key'
style.define 'html_entity', 'preproc'

howl.aux.lpeg_lexer ->
  c = capture
  ws = c 'whitespace', space^1
  operator = c 'operator', S('<>')
  comment = c 'comment', span '<!--', '-->'

  string = c 'string', any {
    span('"', '"', '\\'),
    span("'", "'", '\\')
  }

  char_ref = c 'html_entity', sequence {
    P'&',
    any {
      alpha^1,
      P'#' * P('x')^-1 * digit^1
    }
    ';'
  }

  dtd = sequence {
    c('operator', '<!'),
    c('preproc', alpha^1),
    any({
      string,
      ws,
      c('key', alpha^1)
    })^0
  }

  attribute = sequence {
    c('html_attr', any(alpha, S'-_')^1),
    (c('operator', '=') * string)
  }

  opening_tag = sequence {
    c('operator', P'<'),
    c('html_tag', Cg(complement(space + '>')^1, 'tagname')),
    any({
      attribute,
      ws,
      c('html_attr', any(alpha, S'-_')^1), -- empty attribute
    })^0,
    c('operator', '>')^-1
  }

  closing_tag = sequence {
    c('operator', P'</'),
    c('html_tag', complement(space + '>')^1),
    c('operator', '>')
  }

  cdata = sequence {
    c('operator', '<'),
    c('special', '![CDATA['),
    c('embedded', scan_until(']]>')),
    sequence(c('special', ']]'), c('operator', '>'))^-1
  }

  javascript = sequence {
    opening_tag * back_was 'tagname', 'script'
    sub_lex('javascript', (eol * blank^1)^-1 * '</script'),

    sequence({
      c('operator', '</'),
      c('special', 'script'),
      c('operator', '>'),
    })^-1
  }

  error = c('error', S'&<>') * blank^1

  any {
    dtd,
    comment,
    cdata,
    javascript,
    opening_tag,
    closing_tag,
    attribute,
    char_ref,
    error
    operator,
  }
