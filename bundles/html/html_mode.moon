-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

{
  lexer: bundle_load('html_lexer')

  comment_syntax: { '<!--', '-->' }

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
    '<': '>'
  }

  indentation: {
    more_after: {
      '<%a>%s*$',
      { '<[^/!][^<]*[^/]>%s*$', r'<(br|input)[\\s>][^<]*$' }
    }

    less_for: {
      '^%s*</[^>]+>%s*$'
    }
  }
}
