-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

local lexers

{
  comment_syntax: '//'

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
  }

  lexer: (text, buffer, opts) ->
    lexers or= bundle_load('php_lexer')
    lexer = opts and opts.sub_lexing and lexers.php
    if not lexer and buffer
      buf_start = buffer\sub 1, 30
      if buf_start\match '^%s*<%?'
        lexer = lexers.php
      else
        lexer = lexers.embedded_php

    lexer or= lexers.embedded_php
    lexer text
}
