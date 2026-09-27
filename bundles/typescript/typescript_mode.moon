-- Copyright 2025 The Howl Developers
-- License: MIT

{
  lexer: bundle_load('typescript_lexer')

  comment_syntax: '//'
  lsp_servers: { 'typescript-language-server --stdio' }

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
    '`': '`'
  }
}
