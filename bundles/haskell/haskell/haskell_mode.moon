-- Copyright 2012-2020 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{
  lexer: bundle_load('haskell/haskell_lexer')

  comment_syntax: '--'

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
  }
}
