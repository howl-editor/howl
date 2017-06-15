-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{
  lexer: bundle_load('python_lexer')

  comment_syntax: '#'

  default_config:
    word_pattern: r'\\b[\\pL_][\\pL\\pN_]+\\b'
    inspectors_on_idle: { 'mypy' }

  indentation: {
    more_after: {
      ':%s*$',
      '[[{(]%s*$'
    }

    less_for: {
      '^%s*else:%s*$',
      '^%s*elif:%s*$',
      r'^\\s*[]}\\)]'
    }
  }
  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    "'": "'"
    '"': '"'
  }

  structure: (editor) =>
    [l for l in *editor.buffer.lines when l\match('^%s*class%s') or l\match('^%s*def%s')]
}
