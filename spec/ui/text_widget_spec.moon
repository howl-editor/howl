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

    it 'memory usage is stable', ->
      assert_memory_stays_within '30Kb', ->
        for i = 1, 20
          w = TextWidget!
          w\show!
          w\to_gobject!\destroy!
