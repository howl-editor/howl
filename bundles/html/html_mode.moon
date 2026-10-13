-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

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
