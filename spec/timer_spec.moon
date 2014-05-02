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
