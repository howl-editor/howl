-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import formatting from howl
completer = bundle_load 'css_completer'

class CSSMode
  new: =>
    @lexer = bundle_load 'css_lexer'
    @completers = { completer, 'in_buffer' }

  default_config:
    word_pattern: '[-_%w]+'

  indent_after_patterns: {
    authoritive: true
    '{%s*$',
  }

  dedent_patterns: {
    authoritive: true
    '%s*}%s*$',
  }

  comment_syntax: { '/*', '*/' }

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
  }

  on_char_added: (args, editor) =>
    if args.key_name == 'return'
      return true if formatting.ensure_block editor, '{%s*$', '^%s*}'

    @parent.on_char_added @, args, editor

  on_completion_accepted: (completion, context) =>
    @completer or= completer!
    @completer.finish_completion completion, context
