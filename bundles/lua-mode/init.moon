import style from howl.ui

style.define 'longstring', 'string'

create = ->
  lua_lexer = bundle_file 'lua_lexer.lua'
  {
    lexer: howl.aux.ScintilluaLexer 'lua', lua_lexer
    comment_syntax: '--'
    auto_pairs: {
      '(': ')'
      '[': ']'
      '{': '}'
      '"': '"'
      "'": "'"
    }
  }

mode_reg =
  name: 'lua'
  shebangs: '/lua.*$'
  extensions: 'lua'
  :create

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'lua'

return {
  info:
    author: 'Copyright 2012 Nils Nordman <nino at nordman.org>',
    description: 'Lua mode',
    license: 'MIT',
  :unload
}
