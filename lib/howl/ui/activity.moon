-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
{:bindings} = howl
{:ContentBox, :IndicatorBar, :TextWidget} = howl.ui
{:PropertyObject} = howl.util.moon

class Activity extends PropertyObject
  new: (@opts = {}) =>
    @_keep_focus = false

    @text_widget = TextWidget {
      on_keypress: self\_on_keypress
      on_focus_lost: self\_on_focus_lost
    }

    with @text_widget
      .view.config.view_show_cursor = false

    if opts.text
      @_text = opts.text
      @text_widget\info @_text

    @header = IndicatorBar 'header'
    @spinner = @header\add 'left', 'spinner', Gtk.Spinner!
    @spinner\start!
    @title = @header\add 'left', 'title'
    if @opts.title
      @title.text = @opts.title

    @shortcuts = @header\add 'left', 'shortcuts'

    @box = ContentBox 'activity', @text_widget\to_gobject!, {
      header: @header\to_gobject!
    }
    with @text_widget.view\to_gobject!
      .margin_left = 10
      .margin_top = 5
      .margin_bottom = 5

    super!

  to_gobject: => @box\to_gobject!

  @property keep_focus:
    get: => @_keep_focus
    set: (v) =>
      @_keep_focus = v
      if v
        @text_widget\focus!

  @property text:
    get: => @text_widget.text
    set: (t) =>
      @text_widget.text = ''
      @text_widget.buffer\append t, 'info'
      @text_widget.visible_rows = #@text_widget.buffer.lines

  @property visible:
    get: => @to_gobject!.visible
    set: (v) =>
      if v
        @to_gobject!\show_all!
      else
        @to_gobject!.visible = false

  _on_keypress: (event) =>
    if @opts.keymaps
      bindings.dispatch event, nil, @opts.keymaps, @

    true

  _on_focus_lost: =>
    if @_keep_focus
      @text_widget\focus!
