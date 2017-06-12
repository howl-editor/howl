{:TextWidget} = howl.ui

describe 'TextWidget', ->

  context 'resource management', ->

    it 'widgets are collected as they should', ->
      w = TextWidget!
      list = setmetatable {w}, __mode: 'v'
      w\to_gobject!\destroy!
      w = nil
      collectgarbage!
      assert.is_nil list[1]
