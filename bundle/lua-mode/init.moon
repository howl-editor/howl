mod_name = ...

create = ->
  lua_lexer = vilu.bundle.file_for mod_name, 'lua_lexer.lua'
  lexer: vilu.aux.ScintilluaLexer 'lua', lua_lexer

mode_reg =
  name: 'Lua'
  extensions: 'lua'
  :create

vilu.mode.register mode_reg

return bundle_name: 'lua'
