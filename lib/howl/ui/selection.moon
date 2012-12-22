import Scintilla from howl
import PropertyObject from howl.aux.moon

class Selection extends PropertyObject
  new: (@sci) =>
    super!

  @property empty:
    get: => @range! == nil

  @property anchor:
    get: => @sci\get_anchor! + 1
    set: (pos) => @sci\set_anchor pos - 1

  @property cursor:
    get: => @sci\get_current_pos! + 1
    set: (pos) => @set @anchor, pos

  @property text:
    get: =>
      if @empty then nil
      else
        start_pos, end_pos = @range!
        @sci\get_text_range start_pos - 1, end_pos - 1

    set: (text) =>
      error 'Cannot replace empty selection', 2 if @empty
      start_pos, end_pos = @range!

      with @sci
        \set_target_start start_pos - 1
        \set_target_end end_pos - 1
        \replace_target -1, text

  @property persistent:
    get: => @persistent_anchor != nil
    set: (state) =>
      @persistent_anchor = state and @anchor or nil

  set: (anchor, cursor) => @sci\set_sel anchor - 1, cursor - 1

  range: =>
    cursor, anchor = @cursor, @anchor
    return cursor, anchor if cursor < anchor
    buffer_size = @sci\get_text_length!
    if cursor > anchor or @includes_cursor and cursor <= buffer_size
      return anchor, math.min(cursor + 1, buffer_size + 1) if @includes_cursor
      return anchor, cursor

    nil

  remove: =>
    @sci\set_empty_selection @sci\get_current_pos!
    @persistent = false

  copy: =>
    start_pos, end_pos = @range!
    return unless start_pos
    @sci\copy_range start_pos - 1, end_pos - 1
    @persistent = false
    @remove!

  cut: =>
    start_pos, end_pos = @range!
    return unless start_pos
    @sci\copy_range start_pos - 1, end_pos - 1
    @sci\delete_range start_pos - 1, end_pos - start_pos
    @persistent = false

return Selection
