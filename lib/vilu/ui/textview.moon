import Gtk from lgi
import Scintilla from vilu
import PropertyObject from vilu.aux.moon
import style, theme from vilu.ui

input_process = vilu.input.process

class TextView extends PropertyObject

  new: (buffer) =>
    error('Missing argument #1 (buffer)', 2) if not buffer
    super!

    @sci = Scintilla!
    style.define_styles @sci
    @sci.on_keypress = self\on_keypress

    @bin = Gtk.EventBox {
      Gtk.Alignment {
        top_padding: 1,
        left_padding: 1,
        right_padding: 3,
        bottom_padding: 3,
        Gtk.Box {
          orientation: 'VERTICAL',
          Gtk.EventBox {
            id: 'header'
            Gtk.Box {
              orientation: 'HORIZONTAL'
              border_width: 3
              Gtk.Label id: 'title'
            },
          },
          {
            expand: true
            Gtk.EventBox {
              id: 'sci_box'
              Gtk.Alignment {
                top_padding: 1
                @sci\get_gobject!
              }
            }
          }
        }
      }
    }
    @bin.child.header\get_style_context!\add_class 'header'
    @bin.child.title\get_style_context!\add_class 'title'
    @bin\get_style_context!\add_class 'view'
    @bin.child.sci_box\get_style_context!\add_class 'sci_box'

    @buffer = buffer
    self\_set_appearance!

    getmetatable(self).__to_gobject = => @bin

  self\property buffer:
    get: => @_buf
    set: (buffer) =>
      if @_buf
        @_buf\remove_view_ref self

      @_buf = buffer
      @bin.child.title.label = buffer.title
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

  on_keypress: (args) =>
    input_process @buffer, args

return TextView
