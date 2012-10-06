import destructor from lunar.aux

describe 'destructor(callback, ...)', ->
  it 'returns an object, for which <callback> is called when it is collected', ->
    callback = Spy!
    destructor callback
    collectgarbage!
    assert_true callback.called

  it 'passes any additional arguments given to the callback', ->
    callback = Spy!
    destructor callback, 1, 'foo'
    collectgarbage!
    assert_table_equal callback.called_with, { 1, 'foo' }

  it 'each destructor is unique', ->
    callback = Spy!
    other_callback = Spy!
    destructor callback
    destructor other_callback
    collectgarbage!
    assert_true callback.called
    assert_true other_callback.called
