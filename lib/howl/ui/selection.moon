-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'

import Scintilla, signal from howl
import const_char_p from howl.cdefs
import PropertyObject from howl.aux.moon
import C from ffi

class Selection extends PropertyObject
  new: (@sci) =>
    @includes_cursor = false
    super!

  @property empty:
    get: => @sci\get_selection_empty!

  @property anchor:
    get: => 1 + @sci\char_offset @sci\get_anchor!
    set: (pos) => @sci\set_anchor @sci\byte_offset(pos - 1)

  @property cursor:
    get: => 1 + @sci\char_offset @sci\get_current_pos!
    set: (pos) => @set @anchor, pos

  @property text:
    get: =>
      if @empty then nil
      else
        start_pos, end_pos = @_brange!
        @sci\get_text_range start_pos - 1, end_pos - 1

    set: (text) =>
      error 'Cannot replace empty selection', 2 if @empty
      start_pos, end_pos = @_brange!

      with @sci
        \set_target_start start_pos - 1
        \set_target_end end_pos - 1
        \replace_target -1, text

  @property persistent:
    get: => @persistent_anchor != nil
    set: (state) =>
      @persistent_anchor = state and @anchor or nil

  set: (anchor, cursor) =>
    with @sci
      anchor = \byte_offset anchor - 1
      cursor = \byte_offset cursor - 1
      \set_sel anchor, cursor

  select: (start_pos, end_pos) =>
    if end_pos > start_pos
      end_pos += 1 unless @includes_cursor
    elseif end_pos < start_pos
      start_pos += 1

    @set start_pos, end_pos

  select_all: =>
    @sci\set_sel 0, @sci\get_length! + 1

  range: =>
    start_pos, end_pos = @_brange!
    return nil unless start_pos
    1 + @sci\char_offset(start_pos - 1), 1 + @sci\char_offset(end_pos - 1)

  remove: =>
    unless @empty
      @sci\set_empty_selection @sci\get_current_pos!
      @persistent = false

  copy: =>
    start_pos, end_pos = @_brange!
    return unless start_pos
    @sci\copy_range start_pos - 1, end_pos - 1
    @persistent = false
    @remove!
    signal.emit 'selection-copied'

  cut: =>
    start_pos, end_pos = @_brange!
    return unless start_pos
    @sci\copy_range start_pos - 1, end_pos - 1
    @sci\delete_range start_pos - 1, end_pos - start_pos
    @persistent = false
    signal.emit 'selection-cut'

  _brange: =>
    cursor = @sci\get_current_pos! + 1
    anchor = @sci\get_anchor! + 1
    return cursor, anchor if cursor < anchor
    text = @sci\get_text!
    if cursor > anchor or @includes_cursor and cursor <= #text
      if @includes_cursor -- bump end offset to start of next character
        offset_ptr = const_char_p(text) + cursor - 1

        if offset_ptr[0] != 10 and offset_ptr[0] != 13 -- are we looking at a newline?
          ptr = C.g_utf8_find_next_char offset_ptr, nil
          return anchor, cursor + (ptr - offset_ptr)

      return anchor, cursor

    nil

with signal
  .register 'selection-changed',
    description: [[
Emitted whenever a selection has been changed.

This could be the result of a copy, cut or an explicit request to remove
or create a selection.
]]
    parameters: {
      editor: 'The editor holding the selection'
      selection: 'The selection instance that has been changed'
    }

  .register 'selection-copied',
    description: 'Emitted whenever a selection has been copied.'

  .register 'selection-cut',
    description: 'Emitted whenever a selection has been cut.'

return Selection
