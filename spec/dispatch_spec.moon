-- Copyright 2014-2015 The Howl Developers
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
      it 'returns true, the coroutine status, and the coroutine', ->
        status, co_status, co = dispatch.launch -> nil
        assert.is_true status
        assert.equals 'dead', co_status
        assert.equals 'dead', coroutine.status(co)

    context 'when <f> errors upon start', ->
      it 'returns false, the error message and the coroutine', ->
        status, err, co = dispatch.launch -> error 'foo'
        assert.is_false status
        assert.equals 'foo', err
        assert.equals 'dead', coroutine.status(co)

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
      it 'blocks until released by a wait', ->
        handle = dispatch.park 'out-of-order'
        launched, status = dispatch.launch -> dispatch.resume handle, 'resume-now!'
        assert.is_true launched
        assert.equals "suspended", status

        local result
        launched, status = dispatch.launch ->
          result = dispatch.wait handle

        assert.is_true launched
        assert.equals "dead", status
        assert.equals 'resume-now!', result

  describe 'resume_or_clear()', ->
    context 'when a coroutine is waiting on the handle', ->
      it 'resumes the coroutine, passing along any arguments', ->
        handle = dispatch.park 'test'
        local res

        dispatch.launch ->
          res = { dispatch.wait handle }

        dispatch.resume_or_clear handle, 1, 'two'
        assert.same { 1, 'two' }, res

      it 'propagates any error occurring during resuming', ->
        handle = dispatch.park 'test'

        dispatch.launch ->
          dispatch.wait handle
          error 'boom'

        assert.raises 'boom', -> dispatch.resume_or_clear handle

    context 'when no coroutine is waiting on the handle', ->
      it 'clears the handle', ->
        initial_parked = dispatch.nr_parked!
        handle = dispatch.park 'test'
        assert.equals initial_parked + 1, dispatch.nr_parked!
        dispatch.resume_or_clear handle
        assert.equals initial_parked, dispatch.nr_parked!

    context 'when the handle does not exist', ->
      it 'does nothing and does not error', ->
        assert.has_no.errors ->
          dispatch.resume_or_clear 'non-existent-handle'
