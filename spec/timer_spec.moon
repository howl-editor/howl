require 'howl.cdefs.glib'
C = require('ffi').C
timer = howl.timer

pump_mainloop = ->
  jit.off!
  ctx = C.g_main_context_default!
  count = 0
  while count < 100 and C.g_main_context_iteration(ctx, false) != 0
    count += 1

describe 'timer', ->
  describe 'asap(f, ...)', ->
    it 'invokes <f> once as part of the next main loop iteration', ->
      callback = spy.new -> nil
      timer.asap callback
      pump_mainloop!
      pump_mainloop!
      assert.spy(callback).was_called(1)

    it 'passes along any additional arguments as is', ->
      callback = spy.new (...)-> nil
      timer.asap callback, 'one', nil, 3
      pump_mainloop!
      assert.spy(callback).was_called_with 'one', nil, 3
