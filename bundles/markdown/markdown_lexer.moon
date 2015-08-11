-- Copyright 2013-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.aux.lpeg_lexer ->

  para_pair = (start, stop) ->
    stop = start unless stop
    stop = P(stop)
    P(start) * scan_until(any(stop, eol * eol)) * stop

  -- headers

  h1 = line_start * any {
    capture('h1', '#' * scan_until eol),
    sequence {
      capture('h1', scan_until eol),
      capture('whitespace', eol),
      capture('operator', P'='^1) * #eol
    }
  }
  h2 = line_start * any {
    capture('h2', '##' * scan_until eol),
    sequence {
      capture('h2', scan_until eol),
      capture('whitespace', eol),
      capture('operator', P'-'^1) * #eol
    }
  }
  h3 = capture 'h3', line_start * '###' * scan_until eol

  -- other syntax
  not_escaped = -B'\\'

  emp_start = -B(1) + B(space)
  strong = emp_start * capture 'strong', any { para_pair('*'), para_pair('_') }
  emphasis = emp_start * capture 'emphasis', any { para_pair('**'), para_pair('__') }

  link = not_escaped * sequence {
    capture('operator', '!')^-1,
    capture('link_label', para_pair '[', ']'),
    any({
      sequence {
        capture('link_url', '(' * scan_until S') \t'),
        (blank^1 * capture('string', para_pair('"')) * blank^0)^-1,
        capture('link_url', ')'),
      }
      para_pair '(', ')',
      capture('link_url', P' '^-1 * para_pair '[', ']'),
    })^-1
  }

  ref_def = sequence {
    line_start,
    blank^-3,
    capture('link_label', para_pair '[', ']'),
    ':' * blank^1,
    capture('link_url', complement(space)^1),
    (space^1 * capture('string', any( para_pair('"'), para_pair("'"), para_pair('(', ')'))))^-1
  }

  fenced_code_block = sequence {
    not_escaped,
    capture('operator', '```'),
    sub_lex_by_pattern(alpha^1, 'special', '```')
    capture('operator', '```')^-1,
  }

  code = not_escaped * capture 'embedded', any {
    paired '```',
    para_pair('``'),
    para_pair('`'),
    line_start * (blank^4 + P'\t') * scan_until eol
  }

  block_quote = capture 'operator', line_start * '>'

  list_item = capture 'operator', sequence {
    line_start,
    blank^-3,
    any(digit^1 * P'.', S'*-+'),
    #blank
  }

  h_rule = capture 'number', line_start * (S'-*_' * P' '^0)^1 * #eol

  preamble_def = sequence {
    capture('key', alpha^1 * ':'),
    capture('string', scan_until eol),
    capture('special', eol)
  }

  preamble = line_start * sequence {
    capture('special', P'---' * eol),
    preamble_def^1,
    capture('special', '---'),
    capture('whitespace', eol),
  }

  any {
    preamble,
    h_rule,
    block_quote,
    list_item,
    h3,
    h2,
    h1,
    emphasis,
    strong,
    ref_def,
    link,
    fenced_code_block,
    code,
  }
