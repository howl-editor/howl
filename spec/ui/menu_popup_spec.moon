-- Copyright 2012-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import MenuPopup, highlight, icon from howl.ui

describe 'MenuPopup', ->
  setup -> icon.define 'menu-popup-spec', text: 'I'

  context 'items with an icon', ->
    local popup

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

  context 'the selected item', ->
    local popup, buf

    before_each ->
      popup = MenuPopup { { 'first', icon: 'menu-popup-spec' }, 'second' }, (->)
      buf = popup.list.buffer

    after_each -> popup\release!

    -- the text of the first row starts after its icon, a tab and a space
    flairs_at = (line_nr, column) ->
      highlight.at_pos buf, buf.lines[line_nr].start_pos + column - 1

    it 'has its text flaired with menu_selection, but not its icon', ->
      assert.not_includes flairs_at(1, 1), 'menu_selection'
      assert.includes flairs_at(1, 4), 'menu_selection'
      assert.not_includes flairs_at(2, 1), 'menu_selection'

    it 'has the flair follow the selection', ->
      popup.list\select_next!
      assert.not_includes flairs_at(1, 4), 'menu_selection'
      assert.includes flairs_at(2, 1), 'menu_selection'

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
