-- Copyright 2012-2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import Buffer from howl
import style from howl.ui
append = table.insert

class ActionBuffer extends Buffer
  new:  =>
    super {}
    @collect_revisions = false

  insert: (object, pos, style_name) =>
    local pos_after
    if object.styles
      pos_after = @_insert_styled_object(object, pos)
    else
      @change pos, pos, ->
        pos_after = super object, pos

        if style_name
          @style pos, pos_after - 1, style_name

    pos_after

  append: (object, style_name) =>
    start_pos = @length
    local pos_after
    if object.styles
      pos_after = @_insert_styled_object(object, @length + 1)
    else
      @change start_pos, start_pos, ->
        pos_after = super object

        if style_name
          @style start_pos + 1, @length, style_name

    pos_after

  style: (start_pos, end_pos, style_name) =>
    return if end_pos < start_pos
    start_pos, end_pos = @byte_offset(start_pos), @byte_offset(end_pos + 1)
    @_buffer.styling\set start_pos, end_pos - 1, style_name

  _insert_styled_object: (object, pos) =>
    @change pos, pos, ->
      pos_after = super\insert object.text, pos
      b_start = @byte_offset pos
      @_buffer.styling\apply b_start, object.styles
      pos_after

return ActionBuffer
