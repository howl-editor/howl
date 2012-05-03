package.path ..= ';/home/nino/prog/vilu/lexers/?.lua'

_G.print(package.path)

lpeg = require('lpeg')

-- env = {k, v for k,v in pairs(_G) when type(v) == 'function'}
env = {k, v for k,v in pairs(_G)}
lexer = loadfile '/home/nino/prog/vilu/lexers/lexer.lua'
setfenv lexer, env
lexer = lexer!
env.lexer = lexer


-- lexer = require 'lexer'
--
-- env = :lexer
-- env.lexer = lexer
-- _G.print("env.lexer = " .. _G.tostring(env.lexer))
-- setfenv(lexer.load, env)

load_lexer = (lexer_name) ->
--   env = :lexer
--   env[k] = v for k,v in pairs _G
--   setfenv(lexer.lo, env)
  file = '/home/nino/prog/vilu/lexers/' .. lexer_name .. '.lua'
  l = loadfile file
  setfenv l, env
  _G.print("env.lexer = " .. _G.tostring(env.lexer))
  env.require = (name) -> name == lexer_name and l! or require name
  lexer.load lexer_name

class Theme

  parse: (content) ->
    _G.print(content)
    _G._LEXER = load_lexer 'css'
    lexer.lex content, 32


tokens = Theme.parse [[

editor {
  background-color: #931232;
  color: #343434;
  font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
  font-size: 13px;
}

]]

for t in *tokens
  for k,v in pairs t
    print k .. ' = ' .. tostring(v)
  print '--'

return Theme
