-- Copyright 2012-2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'

import signal, clipboard from howl
import PropertyObject from howl.util.moon
import C from ffi
{:max, :min} = math

class Selection extends PropertyObject
  new: (@_view) =>
    @_sel = _view.selection
    @includes_cursor = false
    @_sel.listener = on_selection_changed: self\_on_selection_changed

    self = @
    @selection_getter = -> self.text
    super!

  @property _buffer: get: => @_view.buffer

  @property empty:
    get: =>
      return @_sel.is_empty unless @includes_cursor
      return true if (@_sel.anchor == nil) and (@_sel.cursor == nil)
      (@_sel.anchor == @_sel.end_pos) and @_sel.end_pos > @_buffer.size

  @property anchor:
    get: =>
      anchor = @_sel.anchor
      anchor and @_buffer\char_offset(anchor)

    set: (pos) =>
      if @empty
        @set pos, max(@_view.cursor.pos - 1, 1)
      else
        @_sel.anchor = @_buffer\byte_offset pos

  @property cursor:
    get: =>
      end_pos = @_sel.end_pos
      end_pos and @_buffer\char_offset end_pos

    set: (pos) => @set @anchor, pos

  @property text:
    get: =>
      return nil if @empty

      start_pos, end_pos = @_brange!
      @_buffer\sub start_pos, end_pos - 1

    set: (text) =>
      error 'Cannot replace empty selection', 2 if @empty
      start_pos, end_pos = @_brange!
      @remove!
      @_buffer\replace start_pos, (end_pos - start_pos), text

  @property persistent:
    get: => @_sel.persistent
    set: (state) => @_sel.persistent = state

  set: (anchor, cursor) =>
    anchor = @_buffer\byte_offset anchor
    end_pos = @_buffer\byte_offset cursor
    @_view.cursor.pos = end_pos
    @_sel\set anchor, end_pos

  select: (start_pos, end_pos) =>
    if end_pos > start_pos
      end_pos += 1 unless @includes_cursor
    elseif end_pos < start_pos
      start_pos += 1

    @set start_pos, end_pos

  select_all: =>
    @_sel\set 1, @_buffer.size + 1

  range: =>
    return nil if @empty
    start_pos, end_pos = @_brange!
    @_buffer\char_offset(start_pos), @_buffer\char_offset(end_pos)

  remove: =>
    unless @empty
      @_sel\clear!
      @persistent = false
      signal.emit 'selection-removed'

  copy: (clip_options = {}, clipboard_options) =>
    return if @empty
    @_copy_to_clipboard clip_options, clipboard_options
    signal.emit 'selection-copied'

  cut: (clip_options = {}, clipboard_options) =>
    return if @empty
    start_pos, end_pos = @_brange!
    @_copy_to_clipboard clip_options, clipboard_options
    @_buffer\delete start_pos, end_pos - start_pos
    @remove!
    @persistent = false
    signal.emit 'selection-cut'

  _on_selection_changed: =>
    signal.emit 'selection-changed'
    unless @empty
      clipboard.primary.text = @selection_getter

  _copy_to_clipboard: (clip_options = {}, clipboard_options) =>
    clip = moon.copy clip_options
    clip.text = @text
    if clip.text
      clipboard.push clip, clipboard_options

  _brange: =>
    cursor = @_sel.end_pos
    anchor = @_sel.anchor
    return cursor, anchor if cursor < anchor
    if (cursor > anchor or @includes_cursor) and cursor <= @_buffer.size
      if @includes_cursor -- bump end offset to start of next character
        ptr = @_buffer\get_ptr(cursor, 1)

        if ptr[0] != 10 and ptr[0] != 13 -- forward unless we are at a newline
          next_ptr = C.g_utf8_find_next_char ptr, nil
          if next_ptr != nil
            cursor += (next_ptr - ptr)

    return min(anchor, cursor), max(anchor, cursor)

with signal
  .register 'selection-changed',
    description: [[
Emitted whenever a selection has been changed.

This could be the result of a copy, cut or an explicit request to remove
or create a selection.
]]

  .register 'selection-removed',
    description: 'Emitted whenever a selection has been removed.'

  .register 'selection-copied',
    description: 'Emitted whenever a selection has been copied.'

  .register 'selection-cut',
    description: 'Emitted whenever a selection has been cut.'

return Selection
