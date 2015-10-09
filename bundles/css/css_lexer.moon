-- Copyright 2013-2015 The Howl Developers
-- License: MIT (see LICENSE.md)

import style from howl.ui

style.define_default 'css_selector', 'keyword'
style.define_default 'css_property', 'key'
style.define_default 'css_unit', 'type'
style.define_default 'css_color', 'string'
style.define_default 'css_at', 'preproc'
style.define_default 'css_pseudo', 'class'

howl.aux.lpeg_lexer ->

  blank = capture 'whitespace', S(' \t')^1
  operator = capture 'operator', S'>{},():'
  name = alpha * (alnum + S'_-')^0

  comment = capture 'comment', span('/*', '*/')

  unit = capture 'css_unit', any('%', 'in', 'cm', 'mm', 'em', 'ex', 'pt', 'pc', 'px')

  integer = S'+-'^-1 * digit^1
  real = S'+-'^-1 * digit^0 * P'.'^-1 * digit^1
  num = capture('number', (integer + real)) * unit^-1
  color = capture 'css_color', P'#' * R('af', 'AF', '09')^0

  dq_string = capture 'string', span('"', '"', '\\')
  sq_string = capture 'string', span("'", "'", '\\')
  string = any(dq_string, sq_string)

  property = capture('css_property', (alpha + '-')^1) * blank^0 * capture('operator', ':')
  value_identifier = any(S'-:.', alpha)^1
  named_parameter = capture('key', name) * blank^0 * capture('operator', S'*^='^1)
  func_value = any(alpha, S'-:.')^1 * '(' * complement(')')^1 * ')'

  decl_value = any {
    comment,
    num,
    color,
    blank,
    named_parameter,
    func_value,
    value_identifier,
    string,
    capture('operator', S'!'),
    complement(S' \t;{},')^1,
  }
  declaration = property * space^0 * (decl_value^0 + blank) * any {
    capture('operator', ';'),
    space^0 * capture('operator', '}'),
    eol,
  }

  at_rule = capture('css_at', P'@' * name) * (blank * dq_string)^-1
  pseudo = capture 'css_pseudo', P':' * name
  attr_spec = capture('operator', '[') * any(named_parameter, blank, dq_string, capture('key', name))^0 * capture('operator', ']')
  selector = capture('css_selector', any(S'.#'^-1 * name, P'*'))

  any {
    comment,
    pseudo,
    declaration,
    at_rule,
    attr_spec,
    selector,
    operator,
  }
