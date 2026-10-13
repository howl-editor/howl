import mode from howl

bundle_load 'style_aliases'
definitions = bundle_load 'mode_definitions'

registered = {}

-- language servers, registered along with their modes
lsp_servers = {
  bash: { name: 'bash-language-server', command: 'bash-language-server start', modes: 'bash' }
  caml: { name: 'ocamllsp', command: 'ocamllsp', modes: 'caml' }
  haskell: {
    name: 'haskell-language-server'
    command: 'haskell-language-server-wrapper --lsp'
    modes: 'haskell'
  }
  java: { name: 'jdtls', command: 'jdtls', modes: 'java' }
  json: {
    name: 'vscode-json-language-server'
    command: 'vscode-json-language-server --stdio'
    modes: 'json'
  }
}

create = (name) ->
  def = definitions[name]
  lexer = bundle_file "lexers/#{name}.lua"
  m = {
    lexer: howl.util.ScintilluaLexer name, lexer
  }
  m[k] = v for k, v in pairs def
  m

register = ->
  -- register all modes, unless there already is a mode available
  -- with the given name
  existing = { name, true for name in *mode.names }

  for name, properties in pairs definitions
    unless existing[name]
      mode_reg =
        :name
        :create

      mode_reg[k] = v for k, v in pairs properties
      mode.register mode_reg
      registered[name] = true
      howl.lsp.register_server lsp_servers[name] if lsp_servers[name]

unload = ->
  for name in pairs definitions
    if registered[name]
      howl.mode.unregister name
      howl.lsp.unregister_server lsp_servers[name].name if lsp_servers[name]

register!

return {
  info:
    author: 'Multiple authors (see README.md)',
    description: 'Collection of basic, mostly lexer-only modes',
    license: 'MIT',
  :unload
}
