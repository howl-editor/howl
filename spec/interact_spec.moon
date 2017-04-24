-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import interact from howl
import Window from howl.ui

describe 'interact', ->
  run_in_coroutine = (f) ->
    wrapped = coroutine.wrap -> f!
    return wrapped!

  before_each ->
    if howl.app.window
      howl.app.window.command_line\abort_all!
    howl.app.window = Window!

  after_each ->
    howl.app.window.command_line\abort_all!
    howl.app.window = nil

  describe '.register(spec)', ->
    it 'raises an error if any of the mandatory fields are missing', ->
      assert.raises 'name', -> interact.register description: 'foo', factory: -> true
      assert.raises 'description', -> interact.register name: 'foo', factory: -> true
      assert.raises 'factory', -> interact.register name: 'foo', description: 'foo'

    it 'accepts one of "factory" or "handler"', ->
      assert.raises 'factory', -> interact.register
        name: 'foo'
        description: 'foo'
        factory: -> true
        handler: -> true

  it '.unregister(name) removes the specified input', ->
    interact.register name: 'foo', description: 'foo', factory: -> true
    interact.unregister 'foo'
    assert.is_nil interact.foo

  context 'calling an interaction .<name>(...)', ->
    before_each ->
      interact.register
        name: 'interaction_call'
        description: 'calls passed in function'
        handler: (f) -> f!

      interaction_instance =
        run: (@finish, f) => f(finish)

      interact.register
        name: 'interaction_with_factory',
        description: 'calls passed in function f(finish)'
        factory: -> moon.copy interaction_instance

    after_each ->
      interact.unregister 'interaction_call'
      interact.unregister 'interaction_with_factory'

    context 'for a spec with .handler', ->
      local i1_spec
      before_each ->
        i1_spec =
          name: 'interaction1'
          description: 'interaction with handler'
          handler: spy.new -> return 'r1', 'r2'
        interact.register i1_spec

      after_each ->
        interact.unregister i1_spec.name

      it 'calls the interaction handler(...), returns result', ->
        multi_value = table.pack interact.interaction1 'arg1', 'arg2'
        assert.spy(i1_spec.handler).was_called_with 'arg1', 'arg2'
        assert.is_same {'r1', 'r2', n:2}, multi_value

    context 'for a spec with .factory', ->
      local i2_spec, i2_interactor
      before_each ->
        i2_interactor =
          run: spy.new (@finish, ...) => return
        i2_spec =
          name: 'interaction2'
          description: 'interaction with factory'
          factory: -> i2_interactor
        interact.register i2_spec

      after_each ->
        interact.unregister i2_spec.name

      it '.<name>(...) invokes the interaction method run(finish, ...)', ->
        run_in_coroutine -> table.pack interact.interaction2 'arg1', 'arg2'
        assert.spy(i2_interactor.run).was_called 1

      it '.<name>(...) returns results passed via finish(...)', ->
        multi_value = nil
        run_in_coroutine -> multi_value = table.pack interact.interaction2!
        i2_interactor.finish 'r1', 'r2'
        assert.is_same {'r1', 'r2', n:2}, multi_value

    context 'nested transactions', ->
      it 'raises an error when attempting to finishing not active interaction', ->
        local captured_finish
        capture_finish = (finish) -> captured_finish = finish

        run_in_coroutine -> interact.interaction_with_factory capture_finish
        finish1 = captured_finish
        finish1!

        assert.has_error finish1, 'Cannot finish - no running activities'

      it 'allows cancelling outer interactions, when nested interactions present', ->
        local captured_finish
        capture_finish = (finish) -> captured_finish = finish

        run_in_coroutine -> interact.interaction_with_factory capture_finish
        run_in_coroutine -> interact.interaction_with_factory capture_finish
        finish2 = captured_finish

        assert.has_no_error finish2

  describe 'sequence()', ->
    it 'runs specified functions in serial, returns table containing all results', ->
      calls = {}
      local result
      run_in_coroutine ->
        result = interact.sequence {'first', 'second', 'third'},
          first: ->
            table.insert calls, 'first'
            'first-result'
          second: ->
            table.insert calls, 'second'
            'second-result'
          third: ->
            table.insert calls, 'third'
            'third-result'
      assert.same {'first', 'second', 'third'}, calls
      assert.same 'first-result', result.first
      assert.same 'second-result', result.second
      assert.same 'third-result', result.third
