-- Copyright 2012-2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import interact from howl

describe 'interact', ->
  describe '.register(spec)', ->
    it 'raises an error if any of the mandatory fields are missing', ->
      assert.raises 'name', -> interact.register description: 'foo', handler: ->
      assert.raises 'description', -> interact.register name: 'foo', handler: ->
      assert.raises 'handler', -> interact.register name: 'foo', description: 'foo'

  it '.unregister(name) removes the specified input', ->
    interact.register name: 'foo', description: 'foo', handler: ->
    interact.unregister 'foo'
    assert.is_nil interact.foo

  it 'calling the interaction calls the handler, returns result', ->
    handler = spy.new -> 'r1', 'r2'
    interact.register
      name: 'interaction_call'
      description: 'calls passed in function'
      :handler

    multi_value = table.pack interact.interaction_call 'arg1', 'arg2'
    assert.spy(handler).was_called_with 'arg1', 'arg2'
    assert.is_same {'r1', 'r2', n:2}, multi_value
