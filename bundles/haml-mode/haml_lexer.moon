-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

import style from howl.ui

style.define 'haml_element', 'keyword'
style.define 'haml_doctype', 'special'
style.define 'haml_id', 'constant'

howl.aux.lpeg_lexer ->

  blank = capture 'whitespace', space^1
  operator = capture 'operator', S',=>-'
  name = alpha * (alnum + S'_-')^0

  dq_string = capture 'string', span('"', '"', '\\')
  sq_string = capture 'string', span("'", "'")
  string = any dq_string, sq_string

  instance_var = capture 'member', '@' * name
  ruby_key = capture 'key', any(P':' * name, name * ':')

  attributes_halt = #S'%%.#'
  hash_attributes = any ruby_key, blank, operator, string, instance_var, complement(P'}' + attributes_halt)
  hash_attribute_list = capture('operator', '{') * hash_attributes^0 * (capture('operator', '}') + attributes_halt)

  html_key = capture('key', (name + ':')^1) * capture('operator', '=')
  html_attributes = any html_key, blank, operator, string, instance_var, complement(P')' + attributes_halt)
  html_attribute_list = capture('operator', '(') * html_attributes^0 * (capture('operator', ')') + attributes_halt)
  attributes = any hash_attribute_list, html_attribute_list

  object_ref = capture('operator', '[') * any(ruby_key, instance_var, blank, operator, complement(']'))^0 * capture('operator', ']')

  ruby_start = (S'&!'^0 * S'-=') + S'&!'
  ruby_finish = eol - B','
  ruby = capture('operator', ruby_start) * blank * capture('embedded', scan_until ruby_finish)
  escape = capture('operator', '\\') * (capture('default', 1) - eol)
  comment = capture 'comment', any('/', '-#') * scan_through_indented!
  doctype = capture 'haml_doctype', span('!!!', eol)
  element = capture('haml_element', '%' * name) * (attributes + object_ref)^-1 * capture('haml_element', S'/<>')^-1
  classes = capture 'class', '.' * name
  id = capture 'haml_id', "#" * name
  filter = capture('preprocessor', ':') * capture('embedded', name * scan_through_indented!)

  any {
    escape
    element,
    classes,
    id,
    comment,
    ruby,
    filter,
    operator,
    doctype
  }
