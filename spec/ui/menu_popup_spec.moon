-- Copyright 2012-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import MenuPopup, icon from howl.ui

describe 'MenuPopup', ->
  context 'items with an icon', ->
    local popup

    setup -> icon.define 'menu-popup-spec', text: 'I'
    after_each -> popup\release!

    it 'are shown with the icon and a tab before the first column', ->
      popup = MenuPopup { { 'first', 'x', icon: 'menu-popup-spec' }, { 'second', 'y' } }, (->)
      lines = [l.text for l in *popup.list_widget.text_widget.buffer.lines]
      assert.match lines[1], '^I\t first +x'
      assert.match lines[2], '^second +y'

    it 'are passed to the callback when chosen', ->
      item = { 'first', icon: 'menu-popup-spec' }
      local chosen
      popup = MenuPopup { item }, (i) -> chosen = i
      popup\choose!
      assert.equals item, chosen

  it 'adds opts.css_class to the popover', ->
    popup = MenuPopup { 'one' }, (->), css_class: 'action-popup'
    assert.includes popup.popover.css_classes, 'action-popup'
    popup\release!

  context 'resource management', ->
    items = {'one', 'two', 'three'}

    it 'popups are collected as they should', ->
      o = MenuPopup items, (->)
      list = setmetatable {o}, __mode: 'v'
      o\release!
      o = nil
      collectgarbage!
      assert.is_nil list[1]
