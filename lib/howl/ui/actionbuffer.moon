import Buffer, Scintilla from howl
import style from howl.ui

class ActionBuffer extends Buffer
  new: (sci = nil) =>
    super {}, sci
    @sci\set_lexer Scintilla.SCLEX_NULL

  insert: (text, pos, style_name) =>
    pos_after = super text, pos

    if style_name
      @style pos, pos_after - 1, style_name

    pos_after

  append: (text, style_name) =>
    start_pos = @length
    super text
    if style_name
      @style start_pos + 1, @length, style_name

  style: (start_pos, end_pos, style_name) =>
    style_num = style.number_for style_name, self
    start_pos, end_pos = @sci\raw!\byte_offset start_pos, end_pos + 1
    @sci\start_styling start_pos - 1, 0xff
    @sci\set_styling end_pos - start_pos, style_num


return ActionBuffer
