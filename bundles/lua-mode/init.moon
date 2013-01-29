create = ->
  lua_lexer = bundle_file 'lua_lexer.lua'
  {
    lexer: howl.aux.ScintilluaLexer 'lua', lua_lexer
    short_comment_prefix: '--'
  }

mode_reg =
  name: 'lua'
  extensions: 'lua'
  :create

howl.mode.register mode_reg

return info:
  name: 'lua_mode',
  author: 'Copyright 2012 Nils Nordman <nino at nordman.org>',
  description: 'Lua mode',
  license: 'MIT',
