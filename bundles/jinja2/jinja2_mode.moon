-- Copyright 2025 The Howl Developers
-- License: MIT (see LICENSE file)

mode = howl.mode

lexers = {}

{
  lexer: (text, buffer) ->
    base = 'html'
    if buffer and buffer.title
      target_ext = buffer.title\match('%.(%w+)%.j[2inja]*$')
      if target_ext
        m = mode.for_extension target_ext
        base = m.name if m

    l = lexers[base or 'default']
    unless l
      l = bundle_load('jinja2_lexer') base
      lexers[base] = l

    l text

  comment_syntax: { '{#', '#}' }

  auto_pairs: {
    '(': ')',
    '[': ']',
    '{': '}',
    '"': '"',
    "'": "'",
  }
}
