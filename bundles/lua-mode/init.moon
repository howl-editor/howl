create = ->
  lua_lexer = bundle_file 'lua_lexer.lua'
  lexer: lunar.aux.ScintilluaLexer 'lua', lua_lexer

mode_reg =
  name: 'Lua'
  extensions: 'lua'
  :create

lunar.mode.register mode_reg

return info:
  name: 'lua_mode',
  author: 'Copyright 2012 Nils Nordman <nino at nordman.org>',
  description: 'Lua mode',
  license: 'MIT',
