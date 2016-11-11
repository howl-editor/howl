import destructor from howl.util

describe 'destructor', ->
  it 'returns an object, for which <callback> is called when it is collected', ->
    callback = Spy!
    destructor callback
    collectgarbage!
    assert.is_true callback.called

  it 'passes any additional arguments given to the callback', ->
    callback = Spy!
    destructor callback, 1, 'foo'
    collectgarbage!
    assert.same callback.called_with, { 1, 'foo' }

  it 'each destructor is unique', ->
    callback = Spy!
    other_callback = Spy!
    destructor callback
    destructor other_callback
    collectgarbage!
    assert.is_true callback.called
    assert.is_true other_callback.called

  it 'defuse() disables the destructor', ->
    callback = Spy!
    d = destructor callback
    d.defuse!
    collectgarbage!
    assert.is_false callback.called
