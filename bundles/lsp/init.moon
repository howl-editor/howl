mode_reg =
  name: 'lsp'
  create: ->
    print 'lsp create'

howl.mode.register mode_reg

test = ->
  LanguageServer = bundle_load('language_server')
  print 'launching language server'
  -- ls = LanguageServer.for_command(
  --   'solargraph stdio',
  --   '/home/nilnor/code/playad/adten-configuration'
  -- )

  ls = LanguageServer.for_command(
    'typescript-language-server --log-level 3 --stdio --tsserver-log-file /tmp/tsserver.log --tsserver-log-verbosity verbose',
    '/home/nilnor/code/playad/resources-js/'
  )

  ls\run!

howl.signal.connect 'mode-registered', (args) ->
  if args.name == 'lsp'
    print 'lsp mode registered'
    -- test!

unload = ->
  print 'unload'
  howl.mode.unregister 'lsp'

print "lsp loaded"

return {
  info:
    author: 'Copyright 2021 The Howl Developers',
    description: 'Language Server Protocol support',
    license: 'MIT',
  :unload,
  util: bundle_load 'util'
}

