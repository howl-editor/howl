-- Copyright 2019 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

(type) ->
  {
    lexer: bundle_load('ini_lexer')(type)

    comment_syntax: if type == 'xdg' or type == 'systemd' then '#' else ';'
    word_pattern: r'\\b[A-Za-z0-9_-]+\\b'

    auto_pairs: {
      '(': ')'
      '[': ']'
      '{': '}'
      "'": "'"
      '"': '"'
    }

    structure: (editor) =>
      [l for l in *editor.buffer.lines when l\match('^%s*%[')]
  }
