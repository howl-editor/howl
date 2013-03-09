ffi = require 'ffi'

import Scintilla, signal from howl
import PropertyObject from howl.aux.moon
import C from ffi

class Selection extends PropertyObject
  new: (@sci) =>
    super!

  @property empty:
    get: => @range! == nil

  @property anchor:
    get: => @sci\raw!\char_offset @sci\get_anchor! + 1
    set: (pos) => @sci\set_anchor @sci\raw!\byte_offset(pos) - 1

  @property cursor:
    get: => @sci\raw!\char_offset @sci\get_current_pos! + 1
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
    if anchor <= cursor
      anchor, cursor = @sci\raw!\byte_offset anchor, cursor
    else
      cursor, anchor = @sci\raw!\byte_offset cursor, anchor

    @sci\set_sel anchor - 1, cursor - 1

  select: (start_pos, end_pos) =>
    if end_pos > start_pos
      end_pos += 1 unless @includes_cursor
    elseif end_pos < start_pos
      start_pos += 1

    @set start_pos, end_pos

  range: =>
    start_pos, end_pos = @_brange!
    return nil unless start_pos
    @sci\raw!\char_offset start_pos, end_pos

  remove: =>
    unless @empty
      @sci\set_empty_selection @sci\get_current_pos!
      @persistent = false
      signal.emit 'selection-removed'

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
    signal.emit 'selection-removed'
    signal.emit 'selection-cut'

  _brange: =>
    cursor = @sci\get_current_pos! + 1
    anchor = @sci\get_anchor! + 1
    return cursor, anchor if cursor < anchor
    raw = @sci\raw!
    if cursor > anchor or @includes_cursor and cursor <= raw.size
      if @includes_cursor -- bump end offset to start of next character
        offset_ptr = raw.ptr + cursor - 1
        ptr = C.g_utf8_find_next_char offset_ptr, nil
        return anchor, cursor + (ptr - offset_ptr)

      return anchor, cursor

    nil

with signal
  .register 'selection-removed',
    description: [[
Emitted whenever a selection has been removed.

This could be the result of a copy, cut or an explicit request to remove
a selection.
]]

  .register 'selection-copied',
    description: 'Emitted whenever a selection has been copied.'

  .register 'selection-cut',
    description: 'Emitted whenever a selection has been cut.'

return Selection
