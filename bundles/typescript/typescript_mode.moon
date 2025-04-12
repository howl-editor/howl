-- Copyright 2025 The Howl Developers
-- License: MIT

{
  lexer: bundle_load('typescript_lexer')

  comment_syntax: '//'

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
    '`': '`'
  }
}
