-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
timer = howl.timer

describe 'timer', ->
  setup -> set_howl_loop!

  describe 'asap(f, ...)', ->
    it 'invokes <f> once as part of the next main loop iteration', (done) ->
      timer.asap async ->
        done!

    it 'passes along any additional arguments as is', (done) ->
      callback = async (...) ->
        assert.same { 'one', nil, 3 }, { ... }
        done!

      timer.asap callback, 'one', nil, 3

  describe 'after(seconds, f, ...)', ->
    it 'invokes <f> once after approximately <seconds>', (done) ->
      timer.after 0, async ->
        done!

  describe 'cancel(handle)', ->
    it 'cancels an asap timer', (done) ->
      invoked = false
      handle = timer.asap async -> invoked = true
      timer.cancel handle

      timer.after 0.05, async ->
        assert.is_false invoked
        done!

    it 'cancels an after timer', (done) ->
      invoked = false
      handle = timer.after 0.05, async -> invoked = true
      timer.cancel handle

      timer.after 0.1, async ->
        assert.is_false invoked
        done!
