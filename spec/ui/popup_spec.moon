-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import Popup from howl.ui
Gtk = require 'ljglibs.gtk'

describe 'Popup', ->
  context 'resource management', ->
    child = Gtk.Box Gtk.ORIENTATION_VERTICAL, {}

    it 'widgets are collected as they should', ->
      o = Popup child
      list = setmetatable {o}, __mode: 'v'
      o\destroy!
      o = nil
      collectgarbage!
      assert.is_true list[1] == nil, 'Popup still lives'
