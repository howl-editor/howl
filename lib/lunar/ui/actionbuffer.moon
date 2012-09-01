import Buffer from lunar
import style from lunar.ui

class ActionBuffer extends Buffer
  new: (sci) =>
    super {}, sci

  insert: (text, pos, style_name) =>
    pos_after = super text, pos

    if style_name
      style_num = style.number_for style_name, self
      @sci\start_styling pos - 1, 0xff
      @sci\set_styling pos_after - pos, style_num

    pos_after

  append: (text, style_name) =>
    start_pos = @size
    super text
    if style_name
      end_pos = @size
      style_num = style.number_for style_name, self
      @sci\start_styling start_pos, 0xff
      @sci\set_styling end_pos - start_pos, style_num

return ActionBuffer
