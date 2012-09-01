import PropertyObject from lunar.aux.moon

class Selection extends PropertyObject
  new: (sci) =>
    super!
    @sci = sci

  self\property empty:
    get: => @sci\get_selection_end! - @sci\get_selection_start! == 0

  self\property anchor:
    get: => if @empty then nil else @sci\get_anchor! + 1
    set: (pos) => @sci\set_anchor pos - 1

  self\property text:
    get: => if @empty then nil else @sci\get_sel_text!
    set: (text) =>
      error 'Cannot replace empty selection' if @empty
      @sci\replace_sel text

  set: (anchor, cursor) => @sci\set_sel anchor - 1, cursor - 1
  remove: => @sci\set_empty_selection @sci\get_current_pos!

  copy: =>
    @sci\copy!
    @persistent = false
    self\remove!

  cut: =>
    @sci\cut!
    @persistent = false

return Selection
