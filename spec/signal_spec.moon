import signal from lunar
import Spy from lunar.spec

describe 'signal', ->
  it 'allows name based signals to be broadcasted to any number of handlers', ->
    handler1 = Spy!
    handler2 = Spy!
    signal.connect 'foo', handler1
    signal.connect 'foo', handler2
    signal.emit 'foo'
    assert_true handler1.called
    assert_true handler2.called

  it 'allows connecting handlers before existing handlers', ->
    value = nil
    signal.connect 'foo', -> value = 'first'
    signal.connect_first 'foo', -> value = 'second'
    signal.emit 'foo'
    assert_equal value, 'first'

  it 'allows disconnecting handlers', ->
    handler = Spy!
    signal.connect 'foo', handler
    signal.disconnect 'foo', handler
    signal.emit 'foo'
    assert_false handler.called

  describe '.emit', ->
    context 'when a handler returns true', ->
      it 'skips invoking subsequent handlers', ->
        handler2 = Spy!
        signal.connect 'foo', -> true
        signal.connect 'foo', handler2
        signal.emit 'foo'
        assert_false handler2.called

      it 'returns true', ->
        signal.connect 'foo', -> true
        assert_true signal.emit 'foo'

    context 'when a handler raises an error', ->
      it 'emits an "error" signal', ->
        err_handler = Spy!
        signal.connect 'error', err_handler
        signal.connect 'fubar', -> error 'BOOM'
        signal.emit 'fubar'
        assert_true err_handler.called

      it 'but it does not emit an "error" signal when processing "error" handlers', ->
        invocations = 0
        signal.connect 'error', ->
          invocations += 1
          error 'BOOM'
        signal.emit 'error'
        assert_equal invocations, 1

      it 'continues processing subsequent handlers', ->
        handler2 = Spy!
        signal.connect 'fubar', -> error 'BOOM'
        signal.connect 'fubar', handler2
        signal.emit 'fubar'
        assert_true handler2.called

    it 'returns false if no handlers returned true', ->
      assert_false signal.emit 'no-such-signal'
