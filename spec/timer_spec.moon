-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
timer = howl.timer
{:get_monotonic_time} = require 'ljglibs.glib'

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

  describe 'after_exactly(seconds, f, ...)', ->
    it 'invokes <f> once after approximately <seconds>', (done) ->
      start = get_monotonic_time!
      timer.after_exactly 0.2, async ->
        elapsed = (get_monotonic_time! - start) / 1000
        assert.is_near 200, elapsed, 10
        done!

  describe 'after_approximately(seconds, f, ...)', ->
    it 'invokes <f> once after approximately <seconds>', (done) ->
      settimeout 2
      start = get_monotonic_time!
      timer.after_approximately 1, async ->
        elapsed = (get_monotonic_time! - start) / 1000
        assert.is_near 1000, elapsed, 250
        done!

  describe 'cancel(handle)', ->
    it 'cancels an asap timer', (done) ->
      invoked = false
      handle = timer.asap async -> invoked = true
      timer.cancel handle

      timer.after 0.05, async ->
        assert.is_false invoked
        done!

    it 'cancels an after_exactly timer', (done) ->
      invoked = false
      handle = timer.after_exactly 0.05, async -> invoked = true
      timer.cancel handle

      timer.after 0.1, async ->
        assert.is_false invoked
        done!

    it 'cancels an after_approximately timer', (done) ->
      settimeout 2
      invoked = false
      handle = timer.after_approximately 0.5, async -> invoked = true
      timer.cancel handle

      timer.after 1.0, async ->
        assert.is_false invoked
        done!
