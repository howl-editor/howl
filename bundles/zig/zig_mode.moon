-- Copyright 2020 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{
  lexer: bundle_load('zig_lexer')
  comment_syntax: '//'
  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
  }

  default_config:
    use_tabs: false
    tab_width: 4
    indent: 4
    edge_column: 100
}
