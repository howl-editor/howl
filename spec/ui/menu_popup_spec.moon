-- Copyright 2012-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import MenuPopup from howl.ui

describe 'MenuPopup', ->
  context 'resource management', ->
    items = {'one', 'two', 'three'}

    it 'popups are collected as they should', ->
      o = MenuPopup items, (->)
      list = setmetatable {o}, __mode: 'v'
      o\release!
      o = nil
      collectgarbage!
      assert.is_nil list[1]
