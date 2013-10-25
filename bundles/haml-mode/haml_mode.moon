-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

class HamlMode
  new: =>
    @lexer = bundle_load('haml_lexer')

  short_comment_prefix: '-#'

  indent_patterns: {
    authoritive: false

    '^%s*[.#%%][%a_-]+%s*$',
    '^%s*-%s+.+|%s*$',
    '^%s*%%html',
  }
