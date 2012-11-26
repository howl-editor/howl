import Buffer, Scintilla from lunar
import style from lunar.ui

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
    start_pos = @size
    super text
    if style_name
      @style start_pos + 1, @size, style_name

  style: (start_pos, end_pos, style_name) =>
    style_num = style.number_for style_name, self
    @sci\start_styling start_pos - 1, 0xff
    @sci\set_styling (end_pos + 1) - start_pos, style_num

return ActionBuffer
