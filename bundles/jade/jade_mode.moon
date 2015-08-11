-- Copyright 2013-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{
  lexer: bundle_load('jade_lexer')

  comment_syntax: '-#'

  indentation: {
    more_after: {
      authoritive: false

      '^%s*[.#%%][%a_-]+%s*$',
      '^%s*-%s+.+|%s*$',
      '^%s*%%html',
    }
  }

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
  }

}
