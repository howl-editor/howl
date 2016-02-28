-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

bundle_load 'go_completer'
{:fmt} = bundle_load 'go_fmt'

{
  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
    "`": "`"
  }

  comment_syntax: '//'

  completers: { 'in_buffer', 'go_completer' }
  
  lexer: bundle_load('go_lexer')

  structure: (editor) =>
    [l for l in *editor.buffer.lines when l\match('^%s*func%s') or l\match('^%s*struct%s') or l\match('^%s*type%s')]
    
  before_save: (buffer) ->
    fmt buffer
}
