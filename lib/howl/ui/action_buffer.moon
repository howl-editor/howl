-- Copyright 2012-2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import Buffer, Scintilla, styler from howl
import style from howl.ui
append = table.insert

class ActionBuffer extends Buffer
  new: (sci = nil) =>
    super {}, sci
    @sci\set_lexer Scintilla.SCLEX_NULL

  insert: (object, pos, style_name) =>
    local pos_after
    if object.styles
      pos_after = @_insert_styled_object(object, pos)
    else
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
      pos_after = super object

      if style_name
        @style start_pos + 1, @length, style_name

    pos_after

  style: (start_pos, end_pos, style_name) =>
    style_num = style.number_for style_name, self
    start_pos, end_pos = @byte_offset(start_pos), @byte_offset(end_pos + 1)
    @sci\start_styling start_pos - 1, 0xff
    @sci\set_styling end_pos - start_pos, style_num

  _insert_styled_object: (object, pos) =>
    super\insert object.text, pos
    b_start = @byte_offset pos
    styler.apply self, b_start, b_start + #object.text, object.styles
    pos + object.text.ulen

return ActionBuffer
