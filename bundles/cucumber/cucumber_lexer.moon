-- Copyright 2013-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.aux.lpeg_lexer ->
  token = capture('keyword', complement(any(':', space))^1)

  feature = sequence {
    line_start,
    capture('whitespace', blank)^0,
    token,
    (capture('whitespace', blank)^0 * token)^-1,
    ':',
    capture('whitespace', blank)^0,
    capture('emphasis', scan_until eol)
  }

  description = sequence {
    line_start,
    capture('whitespace', blank^-2),
    capture('gherkin_description', alpha * scan_until eol),
    capture('whitespace', eol),
  }

  step = line_start * capture('whitespace', blank^4) * capture('gherkin_step', alpha * complement(space)^1)
  tag = capture 'comment', '@' * complement(space)^1
  placeholder = capture 'gherkin_placeholder', '<' * complement('>')^1 * '>'
  table = capture 'table', '|' * scan_until blank^0 * eol
  string = capture 'string', paired '"'

  any {
    feature,
    step,
    tag,
    placeholder,
    table,
    description,
    string
  }
