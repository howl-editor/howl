-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import MenuPopup from howl.ui

describe 'MenuPopup', ->
  context 'resource management', ->
    items = {'one', 'two', 'three'}

    it 'popups are collected as they should', ->
      o = MenuPopup items, (->)
      list = setmetatable {o}, __mode: 'v'
      o\destroy!
      o = nil
      collectgarbage!
      assert.is_nil list[1]

    it 'memory usage is stable', ->
      assert_memory_stays_within '70Kb', 30, ->
        p = MenuPopup items, (->)
        p\destroy!
