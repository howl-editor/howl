-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import Popup from howl.ui
Gtk = require 'ljglibs.gtk'

describe 'Popup', ->
  it 'adds opts.css_class to the popover, keeping its own classes', ->
    plain = Popup Gtk.Box(Gtk.ORIENTATION_VERTICAL, {})
    own_classes = plain.popover.css_classes
    plain\release!

    popup = Popup Gtk.Box(Gtk.ORIENTATION_VERTICAL, {}), css_class: 'action-popup'
    classes = popup.popover.css_classes
    assert.includes classes, 'action-popup'
    assert.includes classes, cls for cls in *own_classes
    popup\release!

  context 'resource management', ->
    child = Gtk.Box Gtk.ORIENTATION_VERTICAL, {}

    it 'widgets are collected as they should', ->
      o = Popup child
      list = setmetatable {o}, __mode: 'v'
      o\release!
      o = nil
      collectgarbage!
      assert.is_true list[1] == nil, 'Popup still lives'
