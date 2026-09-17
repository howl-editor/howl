-- Copyright 2012-2025 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{
  lexer: bundle_load('python_lexer')

  default_config:
    inspectors_on_idle: { 'python-ruff' }
    edge_column: 88

  comment_syntax: '#'
  word_pattern: r'\\b[\\pL_][\\pL\\pN_]+\\b'

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
    is_def = (l) ->
      l\match('^%s*class%s') or
      l\match('^%s*def%s') or
      l\match('^%s*async def%s')

    [l for l in *editor.buffer.lines when is_def(l)]
}
