root_dir = howl.app.root_dir
sl_lexer = root_dir\join('lib/ext/scintillua/lexer.lua').contents

class ScintilluaLexer
  new: (lexer_name, file) =>
    env = {k, v for k,v in pairs _G}
    env._G = env
    lexer = loadstring sl_lexer
    setfenv lexer, env
    @lexer = lexer!
    env.lexer = @lexer
    l = loadfile file
    setfenv l, env
    env.require = (name) -> name == lexer_name and l! or require name
    @lexer.load lexer_name

  lex: (text) =>
    @lexer.lex text, 32

return ScintilluaLexer
