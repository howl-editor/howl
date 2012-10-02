import Gtk from lgi
import Scintilla, signal, keyhandler, config, command from lunar
import PropertyObject from lunar.aux.moon
import style, highlight, theme, IndicatorBar, Cursor, Selection from lunar.ui

editors = setmetatable {}, __mode: 'v'

apply_variable = (method, value) ->
  for e in *editors
    sci = e.sci
    sci[method] sci, value

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
    @_set_appearance!
    append editors, self

  to_gobject: => @bin

  @property buffer:
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

      @_set_config_settings!
      style.set_for_buffer @sci, buffer
      highlight.set_for_buffer @sci, buffer
      buffer\add_sci_ref @sci

  @property current_line: get: => @buffer.lines[@cursor.line]

  focus: => @sci\grab_focus!
  new_line: => @sci\new_line!

  new_line_and_indent: =>
    cur_line = @current_line
    mode = @buffer.mode
    indentation = cur_line.indentation

    @buffer\as_one_undo ->
      @new_line!

      if mode and mode.indent_after
        indentation = mode.indent_after cur_line.text

      if indentation
        @current_line.indentation = indentation
        @cursor.column = indentation + 1


  delete_line: => @sci\line_delete!
  delete_to_end_of_line: => @sci\del_line_right!
  copy_line: => @sci\line_copy!
  paste: => @sci\paste!
  insert: (text) => @sci\add_text #text, text
  tab: => @sci\tab!
  backspace: => @sci\delete_back!

  indent: =>
    if @selection.empty
      column = @cursor.column
      @current_line\indent!
      @cursor.column = column + config.get 'indent', @buffer
    else
      @sci\tab!

  unindent: =>
    if @selection.empty
      column = @cursor.column
      if @current_line.indentation > 0
        @current_line\unindent!
        @cursor.column = math.max(column - config.get('indent', @buffer), 0)
    else
      @sci\back_tab!

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
    @_set_theme_settings!
    @_set_ui_config_settings!

  _set_ui_config_settings: =>
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

    @sci\set_caret_fore c_color
    @sci\set_caret_width c_width

    current_line = v.current_line
    if current_line and current_line.background
      @sci\set_caret_line_back current_line.background

    -- selection
    if v.selection
      sel = v.selection
      @sci\set_sel_back true, sel.background if sel.background
      @sci\set_sel_fore true, sel.color if sel.color

  _set_config_settings: =>
    buf = @buffer
    with @sci
      \set_tab_width config.get('tab_width', buf)
      \set_use_tabs config.get('use_tabs', buf)
      \set_indent config.get('indent', buf)
      \set_tab_indents config.get('tab_indents', buf)
      \set_back_space_un_indents config.get('backspace_unindents', buf)

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
    @_update_position!
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

-- Config variables

with config
  .define
    name: 'tab_width'
    description: 'The width of a tab, in number of characters'
    default: 2
    type_of: 'number'

  .define
    name: 'use_tabs'
    description: 'Whether to use tabs for indentation, and not only spaces'
    default: false
    type_of: 'boolean'

  .define
    name: 'indent'
    description: 'The number of characters to use for indentation'
    default: 2
    type_of: 'number'

  .define
    name: 'tab_indents'
    description: 'Whether tab indents within whitespace'
    default: true
    type_of: 'boolean'

  .define
    name: 'backspace_unindents'
    description: 'Whether backspace unindents within whitespace'
    default: true
    type_of: 'boolean'

  for live_update in *{
    { 'tab_width', 'set_tab_width' }
    { 'use_tabs', 'set_use_tabs' }
    { 'indent', 'set_indent' }
    { 'tab_indents', 'set_tab_indents' }
    { 'backspace_unindents', 'set_back_space_un_indents' }
  }
    .watch live_update[1], (_, value) -> apply_variable live_update[2], value

-- Commands
for cmd_spec in *{
  { 'editor:new-line', 'Adds a new line at the current position', 'new_line' }
  { 'editor:new-line-and-indent', 'Adds a new indented line', 'new_line_and_indent' }
  { 'editor:delete-line', 'Deletes the current line', 'delete_line' }
  { 'editor:delete-to-end-of-line', 'Deletes to the end of line', 'delete_to_end_of_line' }
  { 'editor:copy-line', 'Copies the current line to the clipboard', 'copy_line' }
  { 'editor:paste', 'Pastes the contents of the clipboard at the current position', 'paste' }
  { 'editor:tab', 'Simulates a tab key press', 'tab' }
  { 'editor:backspace', 'Simulates a backspace key press', 'backspace' }
  { 'editor:indent', 'Indents the selected lines, or the current line', 'indent' }
  { 'editor:unindent', 'Unindents the selected lines, or the current line', 'unindent' }
  { 'editor:join-lines', 'Joins the current line with the line below', 'join_lines' }
}
  command.register
    name: cmd_spec[1]
    description: cmd_spec[2]
    handler: -> _G.editor[cmd_spec[3]] _G.editor

return Editor
