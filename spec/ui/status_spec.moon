{:Status} = howl.ui

describe 'Status', ->
  local status

  css_classes = ->
    classes = status.label.css_classes
    table.sort classes
    classes

  before_each ->
    status = Status!

  it 'adds the level as a CSS class next to "status"', ->
    status\warning 'careful'
    assert.same {'status', 'warning'}, css_classes!

  it 'replaces the level class when the level changes', ->
    status\warning 'careful'
    status\error 'oops'
    assert.same {'error', 'status'}, css_classes!

  it 'removes the level class when cleared', ->
    status\info 'hello'
    status\clear!
    assert.same {'status'}, css_classes!
