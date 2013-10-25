-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

class YAMLMode
  new: =>
    @lexer = bundle_load('yaml_lexer')

  default_config:
    use_tabs: false

  short_comment_prefix: '#'

  indent_patterns: {
    ':%s*$',
    '[>|]%s*$'
  }
