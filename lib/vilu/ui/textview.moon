import Gtk from lgi
import Scintilla from vilu
import PropertyObject from vilu.aux.moon
import style, theme, IndicatorBar from vilu.ui

input_process = vilu.input.process

indicators = {}
indicator_placements =
  top_left: true
  top_right: true
  bottom_left: true
  bottom_right: true

class TextView extends PropertyObject

  define_indicator: (id, placement = 'bottom_right') ->
    if not indicator_placements[placement]
      error('Illegal placement "' .. placement .. '"', 2)

    indicators[id] = :id, :placement

  new: (buffer) =>
    error('Missing argument #1 (buffer)', 2) if not buffer
    super!

    @indicator = setmetatable {}, __index: self\_create_indicator

    @sci = Scintilla!
    style.define_styles @sci
    @sci.on_keypress = self\_on_keypress
    @sci.on_update_ui = self\_update_position

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
    @bin\get_style_context!\add_class 'view'
    @bin.child.sci_box\get_style_context!\add_class 'sci_box'

    @buffer = buffer
    self\_set_appearance!

    getmetatable(self).__to_gobject = => @bin

  self\property position: get: => @sci\get_current_pos!
  self\property line: get: => 1 + @sci\line_from_position @position
  self\property column: get: => 1 + @sci\get_column @position

  self\property buffer:
    get: => @_buf
    set: (buffer) =>
      if @_buf
        @_buf\remove_view_ref self

      @_buf = buffer
      @indicator.title.label = buffer.title
      @sci\set_doc_pointer(buffer.doc)
      @sci.on_style_needed = buffer\lex
      @sci\set_style_bits 8
      @sci\set_lexer Scintilla.SCLEX_CONTAINER

      buffer\add_view_ref self

  _set_appearance: =>
    v = theme.current.view
    color = '#000000'
    width = 1

    if v and v.caret
      color = v.caret.color if v.caret.color
      width = v.caret.width if v.caret.width

    @sci\set_caret_fore style.string_to_color color
    @sci\set_caret_width width

  _create_indicator: (indics, id) =>
    def = indicators[id]
    error 'Invalid indicator id "' .. id .. '"', 2 if not def
    y, x = def.placement\match('^(%w+)_(%w+)$')
    label = Gtk.Label single_line_mode: true
    label\get_style_context!\add_class 'indic_' .. id
    bar = y == 'top' and @header or @footer
    bar\add x, label
    label\show!
    indics[id] = label
    label

  _on_keypress: (args) =>
    input_process @buffer, args

  _update_position: () =>
    pos = @line .. ':' .. @column
    @indicator.position.label = pos

-- Default indicators
with TextView
  .define_indicator 'title', 'top_left'
  .define_indicator 'position', 'bottom_right'

return TextView
