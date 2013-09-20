-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

import mode from howl

root_dir = howl.app.root_dir
sl_lexer_file = root_dir\join('lib/ext/scintillua/lexer.lua')
sl_lexer = sl_lexer_file.contents

mt = {
  __call: (text) => @lexer.lex text, 32
}

require_scintillua_lexer = (name) ->
  m = mode.by_name name
  if m
    lexer = m.lexer
    if getmetatable(lexer) == mt
      return lexer.loaded_lexer
  nil

setup_scintillua_styles = (lexer) ->
  empty_style = lexer.style {}
  for name in *{
    'nothing', 'class', 'comment', 'constant', 'definition', 'error', 'function',
    'keyword', 'label', 'number', 'operator', 'regex', 'string', 'preproc', 'tag',
    'type', 'variable', 'whitespace', 'embedded', 'identifier'
  }
    lexer["style_#{name}"] = empty_style

new_from_file = (lexer_name, file) ->
  env = {k, v for k,v in pairs _G}
  env._G = env
  lexer_f = load sl_lexer, tostring sl_lexer_file
  setfenv lexer_f, env
  lexer = lexer_f!
  setup_scintillua_styles lexer
  env.lexer = lexer
  instance = :lexer
  l = assert loadfile file
  setfenv l, env

  env.require = (name) ->
    if name == lexer_name
      mod = l!
      instance.loaded_lexer = mod
      return mod

    require_scintillua_lexer(name)

  lexer.load lexer_name
  return setmetatable instance, mt

return setmetatable {}, __call: (_, lexer_name, file) -> new_from_file lexer_name, file
