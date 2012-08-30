import Gtk from lgi
import Scintilla, signal, keyhandler from vilu
import PropertyObject from vilu.aux.moon
import style, highlight, theme, IndicatorBar, Cursor, Selection from vilu.ui
import string_to_color from Scintilla

indicators = {}
indicator_placements =
  top_left: true
  top_right: true
  bottom_left: true
  bottom_right: true

class Editor extends PropertyObject

  define_indicator: (id, placement = 'bottom_right') ->
    if not indicator_placements[placement]
      error('Illegal placement "' .. placement .. '"', 2)

    indicators[id] = :id, :placement

  new: (buffer) =>
    error('Missing argument #1 (buffer)', 2) if not buffer
    super!

    @indicator = setmetatable {}, __index: self\_create_indicator

    @sci = Scintilla!
    style.register_sci @sci
    @sci.on_keypress = self\_on_keypress
    @sci.on_update_ui = self\_on_update_ui
    @sci.on_focus = self\_on_focus
    @sci.on_focus_lost = self\_on_focus_lost
    @selection = Selection @sci
    @cursor = Cursor @sci, @selection

    @header = IndicatorBar 'header', 3
    @footer = IndicatorBar 'footer', 3

    @bin = Gtk.EventBox {
      Gtk.Alignment {
        top_padding: 1,
        left_padding: 1,
        right_padding: 3,
        bottom_padding: 3,
        Gtk.Box {
          orientation: 'VERTICAL',
          @header\get_gobject!
          {
            expand: true
            Gtk.EventBox {
              id: 'sci_box'
              Gtk.Alignment {
                top_padding: 1
                bottom_padding: 1
                @sci\get_gobject!
              }
            }
          }
          @footer\get_gobject!
        }
      }
    }
    @bin\get_style_context!\add_class 'editor'
    @bin.child.sci_box\get_style_context!\add_class 'sci_box'

    @buffer = buffer
    self\_set_appearance!

  to_gobject: => @bin

  self\property buffer:
    get: => @_buf
    set: (buffer) =>
      if @_buf
        @_buf\remove_sci_ref @sci

      @_buf = buffer
      @indicator.title.label = buffer.title
      @sci\set_doc_pointer(buffer.doc)
      @sci.on_style_needed = buffer\lex
      @sci\set_style_bits 8
      @sci\set_lexer Scintilla.SCLEX_CONTAINER

      style.set_for_buffer @sci, buffer
      highlight.set_for_buffer @sci, buffer
      buffer\add_sci_ref @sci

  focus: => @sci\grab_focus!
  new_line: => @sci\new_line!
  delete_line: => @sci\line_delete!
  delete_to_end_of_line: => @sci\del_line_right!
  copy_line: => @sci\line_copy!
  paste: => @sci\paste!
  insert: (text) => @sci\add_text #text, text

  join_lines: =>
    @buffer\as_one_undo ->
      cur_line = @cursor.line
      @cursor\line_end!
      target_pos = @cursor.pos
      content_start = @buffer.lines[cur_line + 1]\find('[^%s]') or 1
      line_start = @sci\position_from_line cur_line
      @buffer\delete target_pos, (line_start + content_start) - target_pos
      @buffer\insert ' ', @cursor.pos

  _set_appearance: =>
    self\_set_theme_settings!
    self\_set_config_settings!

  _set_config_settings: =>
    -- todo: read from upcoming variables
    with @sci
      \set_caret_line_visible true

      -- Line Number Margin.
      \set_margin_width_n 0, 4 + 4 * \text_width(.STYLE_LINENUMBER, '9')
      \set_margin_width_n 1, 5 -- fold margin

      \set_hscroll_bar false

  _set_theme_settings: =>
    v = theme.current.editor
    -- caret
    c_color = '#000000'
    c_width = 1

    if v.caret
      c_color = v.caret.color if v.caret.color
      c_width = v.caret.width if v.caret.width

    @sci\set_caret_fore string_to_color c_color
    @sci\set_caret_width c_width

    current_line = v.current_line
    if current_line and current_line.background
      @sci\set_caret_line_back string_to_color current_line.background

    -- selection
    if v.selection
      sel = v.selection
      @sci\set_sel_back true, string_to_color sel.background if sel.background
      @sci\set_sel_fore true, string_to_color sel.color if sel.color

  _create_indicator: (indics, id) =>
    def = indicators[id]
    error 'Invalid indicator id "' .. id .. '"', 2 if not def
    y, x = def.placement\match('^(%w+)_(%w+)$')
    bar = y == 'top' and @header or @footer
    indic = bar\add x, id
    indics[id] = indic
    indic

  _on_keypress: (args) =>
    keyhandler.process self, args

  _on_update_ui: =>
    self\_update_position!
    signal.emit 'editor-changed', self

  _update_position: =>
    pos = @cursor.line .. ':' .. @cursor.column
    @indicator.position.label = pos

  _on_focus: (args) =>
    _G.editor = self
    signal.emit 'editor-focused', self

  _on_focus_lost: (args) =>
    signal.emit 'editor-defocused', self

-- Default indicators
with Editor
  .define_indicator 'title', 'top_left'
  .define_indicator 'position', 'bottom_right'

return Editor
