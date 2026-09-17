-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

mode = howl.mode

lexers = {}

{
  lexer: (text, buffer) ->
    base = 'html'
    if buffer
      target_ext = buffer.title\match '%.(%w+)%.etlua'
      if target_ext and target_ext != 'xml'
        m = mode.for_extension target_ext
        base = m.name if m

    l = lexers[base]
    unless l
      l = bundle_load('etlua_lexer') base
      lexers[base] = l

    l text

  comment_syntax: { '<%- --', '-%>' }
  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
    '<': '>'
  }
}
