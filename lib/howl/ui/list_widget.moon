-- Copyright 2012-2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:PropertyObject} = howl.util.moon
{:TextWidget} = howl.ui
{:floor} = math
{:tostring} = _G

class ListWidget extends PropertyObject
  new: (@list, opts = {}) =>
    super!

    @partial = false
    @opts = moon.copy opts
    @text_widget = TextWidget @opts
    @text_widget.visible_rows = 15
    list\insert @text_widget.buffer
    list.max_rows = @text_widget.visible_rows
    list\on_refresh self\_on_refresh

  @property showing: get: => @text_widget.showing
  @property height: get: => @text_widget.height
  @property width: get: => @text_widget.width

  @property max_height_request:
    set: (height) =>
      default_line_height = @text_widget.view\text_dimensions('M').height
      @list.max_rows = floor(height / default_line_height)
      @list\draw!

  @property max_width_request:
    set: (width) =>
      local default_char_width
      if width
        default_char_width = @text_widget.view\text_dimensions('W').width
        @list.max_cols = floor(width / default_char_width)
      else
        @list.max_cols = nil
      @list\draw!

  keymap:
    binding_for:
      ['cursor-up']: => @list\select_prev!
      ['cursor-down']: => @list\select_next!
      ['cursor-page-up']: => @list\prev_page!
      ['cursor-page-down']: => @list\next_page!

  to_gobject: => @text_widget\to_gobject!

  show: =>
    return if @showing
    @text_widget\show!
    @list\draw!

  hide: => @text_widget\hide!

  _on_refresh: =>
    if @text_widget.showing
      @_adjust_height!
      @_adjust_width!
      @text_widget.view.first_visible_line = 1

  _adjust_height: =>
    shown_rows = @list.rows_shown

    if @opts.never_shrink
      @list.min_rows = shown_rows

    @text_widget.visible_rows = shown_rows

  _adjust_width: =>
    if @opts.auto_fit_width
      @text_widget\adjust_width_to_fit!
