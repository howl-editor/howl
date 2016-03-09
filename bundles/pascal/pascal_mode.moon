{
  lexer: bundle_load 'pascal_lexer'

  comment_syntax: { '{', '}' }

  indentation:
    more_after: { r'\\b(else|then|var|const|type|uses|do|begin|repeat|object|record|uses|class|interface)\\s*$', '[[(]%s*$' }
    less_for: { r'\\b(begin|end|until|else)' }

  code_blocks:
    multiline: {
      { r'\\bbegin', r'\\bend[;.]$', 'end;' }
      { r'\\b(object|record|class|interface)\\s*$', r'\\bend;$', 'end;' }
      { r'\\brepeat', r'\\buntil$', 'until' }
    }

  auto_pairs:
    '(': ')'
    '[': ']'
    '{': '}'
    "'": "'"
    '"': '"'
}
