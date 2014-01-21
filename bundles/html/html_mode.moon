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

  indent_after_patterns: {
    '<%a>%s*$',
    { '<[^/!][^<]*[^/]>%s*$', r'<(br|input)[\\s>][^<]*$' }
  }

  dedent_patterns: {
    '^%s*</[^>]+>%s*$'
  }
}
