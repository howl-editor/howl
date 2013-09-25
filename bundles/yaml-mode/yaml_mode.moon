-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

class YAMLMode
  new: =>
    @lexer = bundle_load('yaml_lexer.moon')

  short_comment_prefix: '#'

  indent_patterns: {
    ':%s*$',
    '[>|]%s*$'
  }
