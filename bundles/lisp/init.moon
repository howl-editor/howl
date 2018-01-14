mode_reg =
  name: 'lisp'
  extensions: {
    'cl', -- common lisp
    'el', -- emacs lisp
    'lisp',
    'lsp',
    'hy', -- hylang
    'sch', -- scheme
    'scm',  -- scheme
    'sld', -- scheme: R7RS Library Source
    'sls', -- scheme: R6RS Library Source
    'ss', -- scheme: 'Scheme Source' as used in some implementations (e.g. Chez)
  }
  create: -> bundle_load('lisp_mode')!

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'lisp'

return {
  info:
    author: 'Copyright 2013-2015 The Howl Developers',
    description: 'Lisp mode',
    license: 'MIT',
  :unload
}
