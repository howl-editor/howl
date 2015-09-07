{
  lexer: bundle_load 'kotlin_lexer'

  comment_syntax: { '/*', '*/' }

  auto_pairs:
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
}
