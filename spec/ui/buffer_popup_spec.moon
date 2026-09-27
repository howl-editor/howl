-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
{:ActionBuffer, :BufferPopup} = howl.ui

describe 'BufferPopup', ->
  local widget, window

  before_each ->
    widget = Gtk.Box Gtk.ORIENTATION_VERTICAL, {}
    window = Gtk.Window!
    window.child = widget

  after_each ->
    window\destroy!

  width_of = (popup, text) ->
    popup.view\text_dimensions(text).width

  context 'sizing', ->
    it 'fits a buffer filled after creating the popup once shown', ->
      buf = ActionBuffer!
      popup = BufferPopup buf
      buf\append 'a somewhat longer popup message'
      popup\show widget, pointing_to: {x: 1, y: 1, height: 1}
      assert.is_true popup.width >= width_of(popup, 'a somewhat longer popup message')
      popup\release!

    it 'grows as the buffer changes while showing', ->
      buf = ActionBuffer!
      buf\append 'short'
      popup = BufferPopup buf
      popup\show widget, pointing_to: {x: 1, y: 1, height: 1}
      height = popup.height
      buf\append '\na somewhat longer second line'
      assert.is_true popup.width >= width_of(popup, 'a somewhat longer second line')
      assert.is_true popup.height > height
      popup\release!

    it 'resizes a centered popup as the buffer changes', ->
      buf = ActionBuffer!
      buf\append 'short'
      popup = BufferPopup buf
      popup\show widget
      buf\append ' and then some more'
      assert.is_true popup.width >= width_of(popup, 'short and then some more')
      popup\release!

    it 'follows the buffer when the buffer is switched', ->
      popup = BufferPopup ActionBuffer!
      buf = ActionBuffer!
      buf\append 'a somewhat longer popup message'
      popup.buffer = buf
      assert.is_true popup.width >= width_of(popup, 'a somewhat longer popup message')
      popup\release!

  context 'resource management', ->
    it 'popups are collected as they should', ->
      buf = ActionBuffer!
      o = BufferPopup buf
      list = setmetatable {o}, __mode: 'v'
      o\release!
      o = nil
      collectgarbage!
      assert.is_nil list[1]

    it 'stops listening to the buffer when released', ->
      buf = ActionBuffer!
      popup = BufferPopup buf
      listener = popup._listener
      popup\release!
      listeners = [l for l in *buf._buffer.listeners when l == listener]
      assert.same {}, listeners
