-- Copyright 2012-2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{
  lexer: bundle_load 'pascal_lexer'

  comment_syntax: { '{', '}' }

  indentation:
    more_after: {
      r'\\b(else|then|var|const|type|uses|do|begin|repeat|object|record|uses|class)\\s*$'
      '[[(]%s*$'
      r'(?<!^)\\s*interface\\s*$'
    }
    less_for: { r'\\b(begin|end|until|else)' }

  code_blocks:
    multiline: {
      { r'\\bbegin', r'\\bend[;.]$', 'end;' }
      { r'\\b(object|record|class)\\s*$', r'\\bend;$', 'end;' }
      { r'(?<!^)\\s*interface\\s*$', r'\\bend;$', 'end;' }
      { r'\\brepeat', r'\\buntil$', 'until' }
    }

  auto_pairs:
    '(': ')'
    '[': ']'
    '{': '}'
    "'": "'"
    '"': '"'
}
