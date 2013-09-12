import command, mode from howl
bundle_load 'nrepl_port_input.moon'
nrepl = bundle_load 'nrepl.moon'
parser = bundle_load 'clojure_parser.moon'

register_mode = ->
  mode_reg =
    name: 'clojure'
    extensions: 'clj'
    create: -> bundle_load('clojure_mode.moon')!
    parent: 'lisp'

  mode.register mode_reg

register_commands = ->

  command.register
    name: 'nrepl-connect',
    description: 'Connects to an nrepl instance'
    inputs: { 'nrepl_port' }
    handler: (port) ->
      nrepl.connect port
      log.info "Connected to nrepl at :#{port}"

  command.register
    name: 'nrepl-eval',
    description: 'Evaluates a given Clojure form'
    inputs: { '*string' }
    handler: (form) ->
      res = nrepl.eval form
      if res.value
        log.info "nrepl => #{res.value}"
      else
        log.error "nrepl => <error>"

register_mode!
register_commands!

unload = ->
  mode.unregister 'clojure'
  command.unregister 'nrepl-connect'

return {
  info:
    author: 'Copyright 2013 Nils Nordman <nino at nordman.org>',
    description: 'Clojure mode',
    license: 'MIT',
  :unload
  :nrepl
  :parser
}
