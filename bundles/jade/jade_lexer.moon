-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

import style from howl.ui

style.define 'jade_element', 'keyword'
style.define 'jade_id', 'constant'

howl.aux.lpeg_lexer ->

  dq_string = capture 'string', span('"', '"', '\\')
  -- sq_string = capture 'string', span("'", "'")
  -- string = any dq_string, sq_string
  blank_plus = capture 'whitespace', space^1
  blank = capture 'whitespace', space^0
  ident = alpha^1 * any(digit, alpha)^0

  indented_text_block = capture('operator', '.') * capture('default', scan_through_indented!)
  js_eval_to_eol = capture('operator', P'!'^-1 * '=') * blank * sub_lex('javascript', eol)

  id = capture 'jade_id', "#" * ident
  clz = capture('class', '.' * ident)

  attribute = sequence {
    blank,
    capture('key', alpha^1 * any(digit, alpha, S'_-')^0),
    blank,
    capture('operator', '='),
    blank,
    dq_string
  }

  attr_delimiter = any {
    blank_plus,
    sequence {
      blank,
      capture('operator', ','),
      blank
    }
  }

  attributes = sequence {
    capture('operator', '('),
    (attribute * (attr_delimiter * attribute)^0)^0,
    capture('operator', ')')^-1
  }

  element = sequence {
    line_start,
    blank,
    capture('jade_element', ident),
    any(id, clz)^-1,
    attributes^-1,
    any({
      indented_text_block,
      js_eval_to_eol
    })^-1
  }

  operator = sequence {
    line_start,
    blank,
    capture('operator', S'|=')
  }

  any {
    element,
    line_start * blank * js_eval_to_eol
    operator,
  }
