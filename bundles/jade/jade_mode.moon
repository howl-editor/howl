-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

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
