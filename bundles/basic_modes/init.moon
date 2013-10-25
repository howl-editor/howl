import mode from howl

bundle_load 'style_aliases'
definitions = bundle_load 'mode_definitions'

registered = {}

create = (name) ->
  def = definitions[name]
  lexer = bundle_file "lexers/#{name}.lua"
  m = {
    lexer: howl.aux.ScintilluaLexer name, lexer
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

unload = ->
  for name in pairs definitions
    if registered[name]
      howl.mode.unregister name

register!

return {
  info:
    author: 'Multiple authors (see README.md)',
    description: 'Collection of basic, mostly lexer-only modes',
    license: 'MIT',
  :unload
}
