-- Copyright 2013-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

class YAMLMode
  new: =>
    @lexer = bundle_load('yaml_lexer')

  default_config:
    use_tabs: false

  comment_syntax: '#'

  indentation: {
    more_after: {
      ':%s*$',
      '[>|]%s*$'
    }
  }

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
  }
