-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import formatting from howl

class CSSMode
  new: =>
    @lexer = bundle_load 'css_lexer.moon'
    completer = bundle_load 'css_completer.moon'
    @completers = { completer, 'in_buffer' }

  indent_patterns: {
    authoritive: true
    '{%s*$',
  }

  dedent_patterns: {
    authoritive: true
    '%s*}%s*$',
  }

  on_char_added: (args, editor) =>
    if args.key_name == 'return'
      return true if formatting.ensure_block editor, '{%s*$', '^%s*}'

    @parent.on_char_added @, args, editor
