mode_reg =
  name: 'lisp'
  extensions: { 'cl', 'el', 'lisp', 'lsp' }
  create: -> bundle_load('lisp_mode')!

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'lisp'

return {
  info:
    author: 'Copyright 2013 Nils Nordman <nino at nordman.org>',
    description: 'Lisp mode',
    license: 'MIT',
  :unload
}
