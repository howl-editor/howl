import Gtk from lgi
import Scintilla, Completer, signal, keyhandler, config, command from lunar
import PropertyObject from lunar.aux.moon
import style, highlight, theme, IndicatorBar, Cursor, Selection from lunar.ui
import Searcher, CompletionPopup from lunar.ui

editors = setmetatable {}, __mode: 'v'

apply_variable = (method, value) ->
  for e in *editors
    sci = e.sci
    sci[method] sci, value

apply_property = (name, value) ->
  e[name] = value for e in *editors

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
    listener =
      on_style_needed: self\_on_style_needed
      on_keypress: self\_on_keypress
      on_update_ui: self\_on_update_ui
      on_focus: self\_on_focus
      on_focus_lost: self\_on_focus_lost
      on_char_added: self\_on_char_added
      on_text_inserted: self\_on_text_inserted
      on_text_deleted: self\_on_text_deleted
      on_error: log.error
    @sci.listener = listener

    @selection = Selection @sci
    @cursor = Cursor @sci, @selection
    @searcher = Searcher self

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
      signal.emit 'before-buffer-switch', self, @_buf, buffer

      if @_buf
        @_buf.properties.position = @cursor.pos
        @_buf\remove_sci_ref @sci

      prev_buffer = @_buf
      @_buf = buffer
      @indicator.title.label = buffer.title
      @sci\set_doc_pointer(buffer.doc)
      @sci\set_style_bits 8
      @sci\set_lexer Scintilla.SCLEX_CONTAINER

      @_set_config_settings!
      style.set_for_buffer @sci, buffer
      highlight.set_for_buffer @sci, buffer
      buffer\add_sci_ref @sci

      @cursor.pos = buffer.properties.position or 1
      signal.emit 'after-buffer-switch', self, buffer, prev_buffer

  @property current_line: get: => @buffer.lines[@cursor.line]
  @property current_word: get: => @buffer\word_at @cursor.pos

  @property indentation_guides:
    get: =>
      sci_val = @sci\get_indentation_guides!
      switch sci_val
        when Scintilla.SC_IV_NONE then 'none'
        when Scintilla.SC_IV_REAL then 'real'
        when Scintilla.SC_IV_LOOKBOTH then 'on'
        else '(unknown)'

    set: (value) =>
      sci_value = switch value
        when 'none' then Scintilla.SC_IV_NONE
        when 'real' then Scintilla.SC_IV_REAL
        when 'on' then Scintilla.SC_IV_LOOKBOTH
      error "Unknown value for indentation_guides: #{value}", 2 unless sci_value
      @sci\set_indentation_guides sci_value

  @property caret_line_highlighted:
    get: => @sci\get_caret_line_visible!
    set: (flag) => @sci\set_caret_line_visible flag

  @property horizontal_scrollbar:
    get: => @sci\get_hscroll_bar!
    set: (flag) => @sci\set_hscroll_bar flag

  @property vertical_scrollbar:
    get: => @sci\get_vscroll_bar!
    set: (flag) => @sci\set_vscroll_bar flag

  @property line_numbers:
    get: => @sci\get_margin_width_n(0) > 0
    set: (flag) =>
      width = flag and 4 + 4 * @sci\text_width(Scintilla.STYLE_LINENUMBER, '9') or 0
      @sci\set_margin_width_n 0, width

  focus: => @sci\grab_focus!
  newline: => @sci\new_line!

  smart_newline: =>
    cur_line = @current_line
    mode = @buffer.mode
    indentation = cur_line.indentation

    @buffer\as_one_undo ->
      @newline!
      @current_line.indentation = indentation

      if mode and mode.after_newline
        mode\after_newline @current_line, self

      @cursor.column = @current_line.indentation + 1

  comment: =>
    prefix = @buffer.mode.short_comment_prefix
    return unless prefix
    lines = if @selection.empty
      { @current_line }
    else
      @buffer.lines\for_text_range @selection.anchor, @cursor.pos

    min_indent = math.huge
    min_indent = math.min(min_indent, l.indentation) for l in *lines
    prefix ..= ' '
    current_column = @cursor.column

    @buffer\as_one_undo ->
      for line in *lines
        new_text = line\sub(1, min_indent) .. prefix .. line\sub(min_indent + 1)
        line.text = new_text

      @cursor.column = current_column + #prefix unless current_column == 1

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

  forward_to_match: (str) =>
    pos = @current_line\find str, @cursor.column + 1, true
    @cursor.column = pos if pos

  backward_to_match: (str) =>
    rev_line = @current_line\reverse!
    cur_column = (#rev_line - @cursor.column + 1)
    pos = rev_line\find str, cur_column + 1, true
    @cursor.column = (#rev_line - pos) + 1 if pos

  show_popup: (popup, options = {}) =>
    char_width = @sci\text_width 32, ' '
    char_height = @sci\text_height 0

    x_adjust = 0
    pos = options.position
    pos = @cursor.pos if not pos

    line = @sci\line_from_position pos - 1
    at_eol = @sci\get_line_end_position(line) == pos - 1

    if at_eol
      pos -= 1
      x_adjust = char_width

    x = @sci\point_xfrom_position(pos) + x_adjust
    y = @sci\point_yfrom_position pos

    x -= char_width
    y += char_height + 2

    popup\show @sci\get_gobject!, :x, :y
    @popup = window: popup, :options

  remove_popup: =>
    if @popup
      @popup.window\close!
      @popup = nil

  complete: =>
    completion = CompletionPopup self, @cursor.pos
    if not completion.empty
      @show_popup completion, position: completion.position, persistent: true

  _set_appearance: =>
    @_set_theme_settings!

    with config
      @horizontal_scrollbar = .get 'horizontal_scrollbar', @buffer
      @vertical_scrollbar = .get 'vertical_scrollbar', @buffer
      @caret_line_highlighted = .get 'caret_line_highlighted', @buffer
      @line_numbers = .get 'line_numbers', @buffer

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

    @indentation_guides = config.get('indentation_guides', buf)

  _create_indicator: (indics, id) =>
    def = indicators[id]
    error 'Invalid indicator id "' .. id .. '"', 2 if not def
    y, x = def.placement\match('^(%w+)_(%w+)$')
    bar = y == 'top' and @header or @footer
    indic = bar\add x, id
    indics[id] = indic
    indic

  _on_style_needed: (...) =>
    @buffer\lex ...

  _on_keypress: (event) =>
    @remove_popup! if event.key_name == 'escape'

    if @popup
      if not @popup.window.showing
        @remove_popup!
      else
        if @popup.window.keymap
          return true if keyhandler.dispatch event, { @popup.window.keymap }, @popup.window

        @remove_popup! if not @popup.options.persistent
    else
      @searcher\cancel!

    keyhandler.process self, event

  _on_update_ui: =>
    @_update_position!
    signal.emit 'editor-changed', self

  _update_position: =>
    pos = @cursor.line .. ':' .. @cursor.column
    @indicator.position.label = pos

  _on_focus: (args) =>
    _G.editor = self
    @cursor.pos = @cursor.pos -- this ensures cursor is visible
    signal.emit 'editor-focused', self

  _on_focus_lost: (args) =>
    @remove_popup!
    signal.emit 'editor-defocused', self

  _on_char_added: (args) =>
    handled = signal.emit 'char-added', self, args

    if @popup
      @popup.window\on_char_added self, args if @popup.window.on_char_added
    elseif not handled and #@current_word >= config.completion_popup_after
      @complete!

  _on_text_inserted: (args) =>
    handled = signal.emit 'text-inserted', self, args

    if @popup
      @popup.window\on_text_inserted self, args if @popup.window.on_text_inserted

  _on_text_deleted: (args) =>
    handled = signal.emit 'text-deleted', self, args

    if @popup
      @popup.window\on_text_deleted self, args if @popup.window.on_text_deleted

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

  .define
    name: 'completion_popup_after'
    description: 'Show completion after this many characters'
    default: 2
    type_of: 'number'

  .define
    name: 'indentation_guides'
    description: 'Controls how indentation guides are shown'
    default: 'on'
    options: {
      { 'none', 'No indentation guides are shown' }
      { 'real', 'Indentation guides are shown inside real indentation white space' }
      { 'on', 'Indentation guides are shown' }
    }

  .define
    name: 'horizontal_scrollbar'
    description: 'Whether horizontal scrollbars are shown'
    default: false
    type_of: 'boolean'

  .define
    name: 'vertical_scrollbar'
    description: 'Whether vertical scrollbars are shown'
    default: true
    type_of: 'boolean'

  .define
    name: 'caret_line_highlighted'
    description: 'Whether the caret line is highlighted'
    default: true
    type_of: 'boolean'

  .define
    name: 'line_numbers'
    description: 'Whether line numbers are shown'
    default: true
    type_of: 'boolean'

  for watched_property in *{
   'indentation_guides',
   'horizontal_scrollbar',
   'vertical_scrollbar',
   'caret_line_highlighted',
   'line_numbers'
  }
    .watch watched_property, apply_property

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
  { 'editor:newline', 'Adds a new line at the current position', 'newline' }
  { 'editor:smart-newline', 'Adds a new line, and format as needed', 'smart_newline' }
  { 'editor:comment', 'Comments the selection or current line', 'comment' }
  { 'editor:delete-line', 'Deletes the current line', 'delete_line' }
  { 'editor:delete-to-end-of-line', 'Deletes to the end of line', 'delete_to_end_of_line' }
  { 'editor:copy-line', 'Copies the current line to the clipboard', 'copy_line' }
  { 'editor:paste', 'Pastes the contents of the clipboard at the current position', 'paste' }
  { 'editor:tab', 'Simulates a tab key press', 'tab' }
  { 'editor:backspace', 'Simulates a backspace key press', 'backspace' }
  { 'editor:indent', 'Indents the selected lines, or the current line', 'indent' }
  { 'editor:unindent', 'Unindents the selected lines, or the current line', 'unindent' }
  { 'editor:join-lines', 'Joins the current line with the line below', 'join_lines' }
  { 'editor:complete', 'Starts completion at cursor', 'complete' }
}
  command.register
    name: cmd_spec[1]
    description: cmd_spec[2]
    handler: -> _G.editor[cmd_spec[3]] _G.editor

return Editor
