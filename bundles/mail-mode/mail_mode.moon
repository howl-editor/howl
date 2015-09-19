-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see README.md at the top-level directory of the bundle)

append = table.insert

class MailMode
  new: =>
    @lexer = bundle_load('mail_lexer')

  default_config:
    auto_reflow_text: true
    hard_wrap_column: 72
    indent: 4

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
  }

  line_is_reflowable: (line) =>
    no_break = { '^%s*>', '^%s%s>', '^[%w-]+:%s', '^-' }
    for p in *no_break
      return false if line\find p

    true
