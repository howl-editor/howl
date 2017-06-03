mode_reg =
  name: 'moonscript'
  extensions: 'moon'
  shebangs: '/moon$'
  create: -> bundle_load('moonscript_mode')!

howl.mode.register mode_reg
howl.inspection.register {
  name: 'moonpick',
  factory: ->
    bundle_load('moonpick_inspector')
}

unload = ->
  howl.mode.unregister 'moonscript'
  howl.inspection.unregister 'moonpick'

return {
  info:
    author: 'Copyright 2012-2015 The Howl Developers',
    description: 'Moonscript mode',
    license: 'MIT',
  :unload
}
