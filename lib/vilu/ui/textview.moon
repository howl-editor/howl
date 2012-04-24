import Gtk, GtkSource, Pango from lgi
import Delegator from vilu.aux.moon

input_process = vilu.input.process

class TextView extends Delegator

  new: (buffer) =>
    error('Missing argument #1 (buffer)', 2) if not buffer
    @buffer = buffer
    mt = getmetatable buffer
    source_buffer = if mt and mt.__to_gobject then mt.__to_gobject(buffer) else buffer
    @sv = GtkSource.View
      buffer: source_buffer
      wrap_mode: 'NONE'
      highlight_current_line: true
      show_line_numbers: true
      show_line_marks: true
      auto_indent: true

    @sv.on_key_press_event = self\on_keypress
    @sv\override_font Pango.FontDescription.from_string 'Monospace'
    @scrolled_window = Gtk.ScrolledWindow { @sv }
    getmetatable(self).__to_gobject = => @scrolled_window
    super(@sv)

  on_keypress: (_, event) =>
    input_process self.buffer, event

return TextView
