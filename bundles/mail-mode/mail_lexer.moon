-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see README.md at the top-level directory of the bundle)

{:style} = howl.ui

style.define_default 'mail_level_1', 'green'
style.define_default 'mail_level_2', 'blue'
style.define_default 'mail_level_3', 'cyan'
style.define_default 'mail_level_4', 'comment'
style.define_default 'mail_ref', 'bold'
style.define_default 'mail_link', 'link_url'

howl.aux.lpeg_lexer ->
  c = capture

  -- mail markup conventions
  bold = c 'strong', P'*' * complement('*')^1 * '*'
  emphasis = c 'emphasis', P'_' * complement('_')^1 * '_'
  reference = c 'mail_ref', P'[' * digit^1 * ']'
  link = c 'mail_link', P'http' * P('s')^-1 * '://' * scan_until(blank + eol)

  mail_markup = any {
    separate(any(bold, emphasis)),
    reference,
    link
  }

  -- mail headers / preamble
  end_of_preamble = B(eol) * (eol + '-')
  header_key = alpha * any(alpha, '-')^1 * ':'

  preamble = sequence {
    #(header_key * scan_to(eol))^2,
    sub_lex_by_inline('embedded', end_of_preamble, any {
      c('keyword', P'Subject:') * space^1 * c('h1', scan_until(eol)),
      c('keyword', header_key) * scan_until(eol)
    })
  }

  -- quoted correspondence
  quote_pattern = (start, level) ->
    s = "mail_level_#{level}"
    c(s, start) * sub_lex_by_inline(s, eol, mail_markup)

  quoted = line_start * any {
    quote_pattern('>>>>', 4),
    quote_pattern('>>>', 3),
    quote_pattern('>>    ', 3),
    quote_pattern('>>', 2),
    quote_pattern('>           ', 4),
    quote_pattern('>        ', 3),
    quote_pattern('>    ', 2),
    quote_pattern('>', 1),
    quote_pattern('    ', 1),
  }

  -- comments and signature
  signature = c 'comment', sequence {
    line_start,
    '--',
    eol,
    scan_until(eol * eol)
  }

  comment = c 'comment', line_start * '-' * S'-=' * scan_until(eol)

  -- and that's a wrap
  any {
    quoted,
    preamble
    signature,
    comment,
    mail_markup
  }
