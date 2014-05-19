-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

dispatch = howl.dispatch

describe 'dispatch', ->
  describe 'launch(f, ...)', ->
    it 'invokes <f> in a coroutine with the specified arguments', ->
      f = spy.new ->
        _, is_main = coroutine.running!
        assert.is_false is_main

      dispatch.launch f, 1, nil, 'three'
      assert.spy(f).was_called_with 1, nil, 'three'

    context 'when <f> starts correctly', ->
      it 'returns true and the coroutine status', ->
        status, co_status = dispatch.launch -> nil
        assert.is_true status
        assert.equals 'dead', co_status

    context 'when <f> errors upon start', ->
      it 'returns false and the error message', ->
        status, err = dispatch.launch -> error 'foo'
        assert.is_false status
        assert.equals 'foo', err

  describe 'wait()', ->
    it 'yields until resumed using resume() on the parked handle', ->
      handle = dispatch.park 'test'
      done = false

      dispatch.launch ->
        dispatch.wait handle
        done = true

      assert.is_false done
      dispatch.resume handle
      assert.is_true done

    it 'returns any parameters passed to resume()', ->
      handle = dispatch.park 'test'
      local res

      dispatch.launch ->
        res = { dispatch.wait handle }

      dispatch.resume handle, 1, nil, 'three', nil
      assert.same { 1, nil, 'three', nil }, res

    it 'raises an error when resumed with resume_with_error()', ->
      handle = dispatch.park 'test'
      local err

      dispatch.launch ->
        status, err = pcall dispatch.wait, handle
        assert.is_false status

      dispatch.resume_with_error handle, 'blargh!'
      assert.includes err, 'blargh!'

  describe 'resume()', ->
    it 'propagates any error occurring during resuming', ->
      handle = dispatch.park 'test'

      dispatch.launch ->
        dispatch.wait handle
        error 'boom'

      assert.raises 'boom', -> dispatch.resume handle

    context 'when nothing is yet waiting on the parking', ->
      it 'blocks until released by a wait', (done) ->
        howl_async ->
          handle = dispatch.park 'out-of-order'
          launched, status = dispatch.launch -> dispatch.resume handle, 'resume-now!'
          assert.is_true launched
          assert.equals "suspended", status

          launched, status = dispatch.launch ->
            assert.equals 'resume-now!', dispatch.wait handle
            done!

          assert.is_true launched
          assert.equals "dead", status
