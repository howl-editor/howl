-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gdk = require 'ljglibs.gdk'
Gtk = require 'ljglibs.gtk'
aullar = require 'aullar'
gobject_signal = require 'ljglibs.gobject.signal'
import Completer, signal, bindings, config, command, clipboard, sys from howl
import View from aullar
aullar_config = aullar.config
import PropertyObject from howl.aux.moon
import Searcher, CompletionPopup from howl.ui
import auto_pair from howl.editing
{
  :style,
  :highlight,
  :IndicatorBar,
  :Cursor,
  :Selection,
  :ContentBox
} = howl.ui
{:max, :min, :abs} = math
append = table.insert

_editors = setmetatable {}, __mode: 'v'
editors = -> [e for _, e in pairs _editors when e != nil]

indicators = {}
indicator_placements =
  top_left: true
  top_right: true
  bottom_left: true
  bottom_right: true

apply_variable = (option, value) ->
  for e in *editors!
    e.view.config[option] = value

apply_global_variable = (name, value) ->
  aullar_config[name] = value

apply_property = (name, value) ->
  e[name] = value for e in *editors!

signal.connect 'buffer-saved', (args) ->
  for e in *editors!
    e\remove_popup! if e.buffer == args.buffer

signal.connect 'buffer-title-set', (args) ->
  buffer = args.buffer
  for e in *editors!
    if buffer == e.buffer
      e.indicator.title.label = buffer.title

class Editor extends PropertyObject

  register_indicator: (id, placement = 'bottom_right', factory) ->
    if not indicator_placements[placement]
      error('Illegal placement "' .. placement .. '"', 2)

    indicators[id] = :id, :placement, :factory

  unregister_indicator: (id) ->
    e\_remove_indicator id for e in *editors!
    indicators[id] = nil

  new: (buffer) =>
    error('Missing argument #1 (buffer)', 2) if not buffer
    super!

    @indicator = setmetatable {}, __index: self\_create_indicator
    @view = aullar.View!

    listener =
      on_key_press: self\_on_key_press
      on_button_press: self\_on_button_press
      on_focus_in: self\_on_focus
      on_focus_out: self\_on_focus_lost
      on_insert_at_cursor: self\_on_insert_at_cursor
      on_delete_back: self\_on_delete_back
      on_preedit_start: -> log.info "In pre-edit mode.."
      on_preedit_change: (_, args) ->
        log.info "Pre-edit: #{args.str} (Enter to submit, escape to cancel)"
      on_preedit_end: -> log.info "Pre-edit mode finished"

    @view.listener = listener
    @view.cursor.listener = {
      on_pos_changed: self\_on_pos_changed
    }

    @selection = Selection @view
    @cursor = Cursor self, @selection
    @searcher = Searcher self
    @completion_popup = CompletionPopup self

    @header = IndicatorBar 'header'
    @footer = IndicatorBar 'footer'
    content_box = ContentBox 'editor', @view\to_gobject!, {
      header: @header\to_gobject!,
      footer: @footer\to_gobject!
    }
    @bin = content_box\to_gobject!
    @bin.can_focus = true

    @_handlers = {}
    append @_handlers, @bin\on_destroy self\_on_destroy
    append @_handlers, @bin\on_focus_in_event -> @view\grab_focus!

    @buffer = buffer
    @_is_previewing = false
    @has_focus = false

    append _editors, self

  to_gobject: => @bin

  @property buffer:
    get: => @_buf
    set: (buffer) =>
      signal.emit 'before-buffer-switch', editor: self, current_buffer: @_buf, new_buffer: buffer
      @_show_buffer buffer
      signal.emit 'after-buffer-switch', editor: self, current_buffer: buffer, old_buffer: prev_buffer

  @property current_line: get: => @buffer.lines[@cursor.line]
  @property current_context: get: => @buffer\context_at @cursor.pos

  @property indentation_guides:
    get: =>
      show = @view.config.view_show_indentation_guides
      show and 'on' or 'none'

    set: (value) =>
      val = switch value
        when 'none' then false
        when 'on' then true
        else
          error "Unknown value for indentation_guides: #{value}"

      @view.config.view_show_indentation_guides = val

  @property edge_column:
    get: => @view.config.view_edge_column
    set: (v) => @view.config.view_edge_column = v

  @property line_padding:
    get: => @view.config.view_line_padding
    set: (v) => @view.config.view_line_padding = v

  @property line_wrapping:
    get: => @view.config.view_line_wrap
    set: (value) =>
      unless value\umatch r'^(?:none|word|character)$'
        error "Unknown value for line_wrapping: #{value}", 2

      @view.config.view_line_wrap = value

  @property line_wrapping_navigation:
    get: => @view.config.view_line_wrap_navigation
    set: (value) =>
      unless value\umatch r'^(?:real|visual)$'
        error "Unknown value for line_wrapping_navigation: #{value}", 2

      @view.config.view_line_wrap_navigation = value

  @property cursor_line_highlighted:
    get: => @view.config.view_highlight_current_line
    set: (flag) =>
      @view.config.view_highlight_current_line = flag

  @property horizontal_scrollbar:
    get: => @view.config.view_show_h_scrollbar
    set: (flag) => @view.config.view_show_h_scrollbar = flag

  @property vertical_scrollbar:
    get: => @view.config.view_show_v_scrollbar
    set: (flag) =>
      @view.config.view_show_v_scrollbar = flag

  -- @property overtype:
  --   get: => @sci\get_overtype!
  --   set: (flag) => @sci\set_overtype flag

  @property lines_on_screen:
    get: => @view.lines_showing

  @property line_at_top:
    get: => @view.first_visible_line
    set: (nr) => @view.first_visible_line = nr

  @property line_at_bottom:
    get: => @view.last_visible_line
    set: (nr) => @view.last_visible_line = nr

  @property line_at_center:
    get: => @view.middle_visible_line
    set: (nr) => @view.middle_visible_line = nr

  @property line_numbers:
    get: => @view.config.view_show_line_numbers
    set: (flag) => @view.config.view_show_line_numbers = flag

  @property active_lines: get: =>
    return if @selection.empty
      { @current_line }
    else
      @buffer.lines\for_text_range @selection.anchor, @selection.cursor

  @property active_chunk: get: =>
    return if @selection.empty
      @buffer\chunk 1, @buffer.length
    else
      start, stop = @selection\range!
      @buffer\chunk start, stop - 1

  @property current_mode: get: =>
    return @last_mode if @last_pos and @cursor.pos == @last_pos and @last_mode == @buffer.mode
    @last_pos = @cursor.pos
    @last_mode = @buffer\mode_at @cursor.pos
    @last_mode

  refresh_display: => @view\refresh_display from_line: 1, invalidate: true
  grab_focus: => @view\grab_focus!
  newline: =>
    @buffer\as_one_undo ->
      @view\insert @buffer.eol

  shift_right: =>
    cursor_line, cursor_col = @cursor.line, @cursor.column
    anchor_line, anchor_col = nil, nil

    unless @selection.empty
      line = @buffer.lines\at_pos @selection.anchor
      anchor_line = line.nr
      anchor_col = line\virtual_column (@selection.anchor - line.start_pos) + 1

    @transform_active_lines (lines) ->
      for line in *lines
        line\indent!

    if anchor_line
      line = @buffer.lines[anchor_line]
      unless anchor_col == 1 and anchor_line > cursor_line
        anchor_col += @buffer.config.indent

      real_column = line\real_column anchor_col
      @selection.anchor = line.start_pos + real_column - 1

    unless cursor_col == 1 and cursor_line > anchor_line
      cursor_col += @buffer.config.indent

    @cursor\move_to {
      line: cursor_line,
      column: cursor_col,
      extend: anchor_line != nil
    }

  shift_left: =>
    cursor_line, cursor_col = @cursor.line, @cursor.column
    anchor_line, anchor_col, adjust_anchor = nil, nil, false
    adjust_cursor = @current_line.indentation != 0

    unless @selection.empty
      line = @buffer.lines\at_pos @selection.anchor
      anchor_line = line.nr
      anchor_col = line\virtual_column (@selection.anchor - line.start_pos) + 1
      adjust_anchor = line.indentation != 0

    @transform_active_lines (lines) ->
      for line in *lines
        if line.indentation > 0
          line\unindent!

    if anchor_line
      line = @buffer.lines[anchor_line]
      anchor_col -= @buffer.config.indent if adjust_anchor
      real_column = line\real_column max(1, anchor_col)
      @selection.anchor = line.start_pos + real_column - 1

    cursor_col -= @buffer.config.indent if adjust_cursor

    @cursor\move_to {
      line: cursor_line,
      column: max(1, cursor_col),
      extend: anchor_line
    }

  transform_active_lines: (f) =>
    lines = @active_lines
    return if #@active_lines == 0
    start_pos = @active_lines[1].start_pos
    end_pos = @active_lines[#@active_lines].end_pos
    @buffer\change start_pos, end_pos, -> f lines

  with_position_restored: (f) =>
    line, column, indentation, top_line = @cursor.line, @cursor.column, @current_line.indentation, @line_at_top
    status, ret = pcall f, self
    @cursor.line = line
    delta = @current_line.indentation - indentation
    @cursor.column = max 1, column + delta
    @line_at_top = top_line
    error ret unless status

  preview: (buffer) =>
    unless @_is_previewing
      @_pre_preview_buffer = @buffer
    @_show_buffer buffer, preview: true

  cancel_preview: =>
    if @_is_previewing and @_pre_preview_buffer
      @_show_buffer @_pre_preview_buffer
      @_pre_preview_buffer = nil

  indent: => if @current_mode.indent then @current_mode\indent self

  indent_all: =>
    @with_position_restored ->
      @selection\select_all!
      @indent!

  comment: => if @current_mode.comment then @current_mode\comment self
  uncomment: => if @current_mode.uncomment then @current_mode\uncomment self
  toggle_comment: =>
    if @current_mode.toggle_comment then @current_mode\toggle_comment self

  delete_line: => @buffer.lines[@cursor.line] = nil

  delete_to_end_of_line: (opts = {}) =>
    cur_line = @current_line
    if opts.no_copy
      cur_line.text = cur_line.text\usub 1, @cursor.column_index - 1
    else
      end_pos = cur_line.end_pos
      end_pos -= 1 if cur_line.has_eol
      @selection\select @cursor.pos, end_pos
      @selection\cut!

  copy_line: =>
    clipboard.push text: @current_line.text, whole_lines: true

  paste: (opts = {})=>
    clip = opts.clip or clipboard.current
    return unless clip

    @active_chunk\delete! unless @selection.empty

    if not clip.whole_lines
      if opts.where == 'after'
        if @cursor.at_end_of_line
          @insert(' ')
        else
          @cursor\right!

      @insert clip.text
    else
      line = @current_line

      if opts.where == 'after'
        line = @buffer.lines\insert @current_line.nr + 1, ''
      elseif not clip.text\ends_with @buffer.eol
        line = @buffer.lines\insert line.nr, ''

      @cursor.pos = line.start_pos

      @with_position_restored ->
        @insert clip.text

  insert: (text) => @view\insert text

  smart_tab: =>
    if not @selection.empty
      @shift_right!
      return

    conf = @buffer.config
    if conf.tab_indents and @current_context.prefix.is_blank
      cur_line = @current_line
      next_indent = cur_line.indentation + config.indent
      next_indent -= (next_indent % config.indent)
      cur_line.indentation = next_indent
      @cursor.column = next_indent + 1
    else if conf.use_tabs
      @view\insert '\t'
    else
      @view\insert string.rep(' ', conf.indent)

  smart_back_tab: =>
    if not @selection.empty
      @shift_left!
      return

    conf = @buffer.config
    if conf.tab_indents and @current_context.prefix.is_blank
      cur_line = @current_line
      cur_line\unindent!
      @cursor.column = cur_line.indentation + 1
    else
      return if @cursor.column == 1
      tab_stops = math.floor (@cursor.column - 1) / conf.tab_width
      col = tab_stops * conf.tab_width + 1
      col -= conf.tab_width if col == @cursor.column
      @cursor.column = col

  delete_back: =>
    if @selection.empty and @current_context.prefix\match '^%s+$'
      if @buffer.config.backspace_unindents
        cur_line = @current_line
        cur_line\unindent!
        @cursor.column = cur_line.indentation + 1
        return

    @view\delete_back!

  delete_back_word: =>
    if @selection.empty
      pos = @cursor.pos
      @cursor\word_left!
      @buffer\delete @cursor.pos, pos-1
    else
      @view\delete_back!

  delete_forward: =>
    if @selection.empty
      unless @cursor.at_end_of_file
        @buffer\delete @cursor.pos, @cursor.pos
    else
      @active_chunk\delete!

  delete_forward_word: =>
    if @selection.empty
      pos = @cursor.pos
      @cursor\word_right!
      @buffer\delete pos, @cursor.pos-1
    else
      @active_chunk\delete!

  join_lines: =>
    @buffer\as_one_undo ->
      cur_line = @current_line
      next_line = cur_line.next
      return unless next_line
      target_column = #cur_line + 1
      content_start = next_line\ufind('%S') or 1
      cur_line.text ..= ' ' .. next_line.text\sub content_start, -1
      @cursor.column_index = target_column
      @buffer.lines[next_line.nr] = nil
      @cursor.column_index = target_column

  duplicate_current: =>
    if @selection.empty
      line = @current_line
      target_line = line.nr + 1
      @buffer.lines\insert target_line, line.text
      @line_at_bottom = target_line if @line_at_bottom < target_line
    else
      {:anchor, :cursor} = @selection
      @buffer\insert @selection.text, max(anchor, cursor)
      @selection\set anchor, cursor

  cut: =>
    if @selection.empty
      clipboard.push text: @current_line.text, whole_lines: true
      @buffer.lines[@cursor.line] = nil
    else
      @selection\cut!

  copy: =>
    if @selection.empty
      clipboard.push text: @current_line.text, whole_lines: true
    else
      @selection\copy!

  cycle_case: =>
    _capitalize = (word) ->
      word\usub(1, 1).uupper .. word\usub(2).ulower

    _cycle_case = (text) ->
      is_lower = text.ulower == text
      is_upper = text.uupper == text
      if is_lower
        text.uupper
      elseif is_upper
        text\gsub '%S+', _capitalize
      else
        text.ulower

    if @selection.empty
      curword = @current_context.word
      curword.text = _cycle_case curword.text
    else
      anchor, cursor = @selection.anchor, @selection.cursor
      @selection.text = _cycle_case @selection.text
      @selection\set anchor, cursor

  forward_to_match: (str) =>
    pos = @current_line\ufind str, @cursor.column_index + 1, true
    @cursor.column_index = pos if pos

  backward_to_match: (str) =>
    rev_line = @current_line.text.ureverse
    cur_column = (rev_line.ulen - @cursor.column_index + 1)
    pos = rev_line\ufind str, cur_column + 1, true
    @cursor.column_index = (rev_line.ulen - pos) + 1 if pos

  show_popup: (popup, options = {}) =>
    @remove_popup!

    dimensions = @view\text_dimensions 'M'
    x_adjust = 0
    pos = @buffer\byte_offset options.position or @cursor.pos
    coordinates = @view\coordinates_from_position pos
    x = coordinates.x
    y = coordinates.y2 + 2

    popup\show @view\to_gobject!, :x, :y
    @popup = window: popup, :options

  remove_popup: =>
    if @popup
      if @popup.options.keep_alive
        @popup.window\close!
      else
        @popup.window\destroy!

      @popup = nil

  complete: =>
    return if @completion_popup.showing
    @completion_popup\complete!
    if not @completion_popup.empty
      @show_popup @completion_popup, {
        position: @completion_popup.position,
        persistent: true,
        keep_alive: true
      }

  undo: =>
    if @buffer.can_undo
      @buffer\undo!
    else
      log.warn "Can't undo: already at oldest stored revision"

  redo: => @buffer\redo!

  scroll_up: =>
    @view.first_visible_line -= 1
    @view.cursor\ensure_in_view!

  scroll_down: =>
    @view.first_visible_line += 1
    @view.cursor\ensure_in_view!

  range_is_visible: (start_pos, end_pos) =>
    start_line = @buffer.lines\at_pos(start_pos).nr
    end_line = @buffer.lines\at_pos(end_pos).nr

    return start_line >= @line_at_top and end_line <= @line_at_bottom

  ensure_visible: (pos) =>
    return if @range_is_visible pos, pos

    line = @buffer.lines\at_pos(pos).nr
    if @line_at_top > line
      @line_at_top = math.max 1,  line - 2
    else
      @line_at_bottom = math.min #@buffer.lines, line + 2

  -- private
  _show_buffer: (buffer, opts={}) =>
    @selection\remove!

    if @_buf
      @_buf.properties.position = @cursor.pos
      @_buf.properties.line_at_top = @line_at_top
      @_buf\remove_view_ref @view
      unless @_is_previewing
        @_buf.last_shown = sys.time!

    @_is_previewing = opts.preview
    prev_buffer = @_buf
    @_buf = buffer
    @indicator.title.label = buffer.title

    if buffer.activity and buffer.activity.is_running!
      with @indicator.activity
        \start!
        \show!
    elseif rawget(@indicator, 'activity')
      with @indicator.activity
        \stop!
        \hide!

    @view.buffer = buffer._buffer

    @_set_config_settings!
    buffer\add_view_ref!

    if buffer.properties.line_at_top
      @line_at_top = buffer.properties.line_at_top

    pos = buffer.properties.position or 1
    pos = max 1, min pos, #buffer + 1
    if @cursor.pos != pos
      @cursor.pos = pos
    else
      @_on_pos_changed!

  _set_config_settings: =>
    buf = @buffer
    config = buf.config
    view_conf = @view.config

    with config
      @indentation_guides = .indentation_guides
      @line_wrapping = .line_wrapping
      @line_wrapping_navigation = .line_wrapping_navigation
      @horizontal_scrollbar = .horizontal_scrollbar
      @vertical_scrollbar = .vertical_scrollbar
      @cursor_line_highlighted = .cursor_line_highlighted
      @line_numbers = .line_numbers
      @line_padding = .line_padding
      @edge_column = .edge_column
      view_conf.cursor_blink_interval = .cursor_blink_interval
      view_conf.view_indent = .indent
      view_conf.view_tab_size = .tab_width
      view_conf.view_font_name = .font_name
      view_conf.view_font_size = .font_size
      view_conf.view_line_wrap_symbol = .line_wrapping_symbol

  _create_indicator: (indics, id) =>
    def = indicators[id]
    error 'Invalid indicator id "' .. id .. '"', 2 if not def
    y, x = def.placement\match('^(%w+)_(%w+)$')
    bar = y == 'top' and @header or @footer
    widget = def.factory and def.factory! or nil
    indic = bar\add x, id, widget
    indics[id] = indic
    indic

  _remove_indicator: (id) =>
    def = indicators[id]
    return unless def
    y, x = def.placement\match('^(%w+)_(%w+)$')
    bar = y == 'top' and @header or @footer
    bar\remove id
    @indicator[id] = nil

  _on_destroy: =>
    for h in *@_handlers
      gobject_signal.disconnect h

    @buffer\remove_view_ref!
    @completion_popup\destroy!
    @view\destroy!
    @buffer.last_shown = sys.time! unless @_is_previewing
    signal.emit 'editor-destroyed', editor: self

  _on_key_press: (view, event) =>
    @remove_popup! if event.key_name == 'escape'

    if @popup
      if not @popup.window.showing
        @remove_popup!
      else
        if @popup.window.keymap
          return true if bindings.dispatch(event, 'popup', { @popup.window.keymap }, @popup.window)

        @remove_popup! if not @popup.options.persistent
    else
      @searcher\cancel!

    if not bindings.is_capturing and auto_pair.handle event, @
      @remove_popup!
      return true

    maps = { @buffer.keymap, @current_mode and @current_mode.keymap }
    return true if bindings.process event, 'editor', maps, self

  _on_button_press: (view, event) =>
    if event.type == Gdk.GDK_2BUTTON_PRESS
      group = @current_context.word
      group = @current_context.token if group.empty

      unless group.empty
        @selection\set group.start_pos, group.end_pos + 1
        true

    elseif event.type == Gdk.GDK_3BUTTON_PRESS
      line = @current_line
      @selection\set line.start_pos, line.end_pos

  _on_pos_changed: =>
    @_update_position!
    @_brace_highlight!
    signal.emit 'cursor-changed', editor: self, cursor: @cursor

  _brace_highlight: =>
    return unless @view.showing

    {:buffer, :cursor} = @view

    if @_brace_highlighted
      buffer.markers\remove name: 'brace_highlight'
      @_brace_highlighted = false

    should_highlight = @buffer.config.matching_braces_highlighted
    return unless should_highlight
    auto_pairs = @current_mode.auto_pairs
    return unless auto_pairs

    get_brace_pos = (buffer, pos, auto_pairs) ->
      cur_char = buffer\sub pos, pos
      matching = auto_pairs[cur_char]
      return cur_char, pos, matching, true if matching

      for k, v in pairs auto_pairs
        if v == cur_char
          return cur_char, pos, k, false

    pos = cursor.pos
    cur_char, start_pos, matching, forward = get_brace_pos buffer, pos, auto_pairs
    if not matching and pos > 1
      cur_char, start_pos, matching, forward = get_brace_pos buffer, pos - 1, auto_pairs

    return if not matching or cur_char == matching

    match_pos = if forward
      last_visible_line = buffer\get_line(@view.last_visible_line)
      search_to = last_visible_line and last_visible_line.end_offset or buffer.size
      buffer\pair_match_forward(start_pos, matching, search_to)
    else
      search_to = buffer\get_line(@view.first_visible_line).start_offset
      buffer\pair_match_backward(start_pos, matching, search_to)

    if match_pos and abs(match_pos - start_pos) > 1
      buffer.markers\add {{
        name: 'brace_highlight',
        flair: 'brace_highlight',
        start_offset: match_pos,
        end_offset: match_pos + 1
      }}
      @_brace_highlighted = true

  _update_position: =>
    pos = @cursor.line .. ':' .. @cursor.column
    @indicator.position.label = pos

  _on_focus: (args) =>
    howl.app.editor = self
    @has_focus = true
    signal.emit 'editor-focused', editor: self
    false

  _on_focus_lost: (args) =>
    @has_focus = false
    @remove_popup!
    signal.emit 'editor-defocused', editor: self
    false

  _on_insert_at_cursor: (_, args) =>
    params = moon.copy args
    params.editor = self
    return if signal.emit('insert-at-cursor', params) == signal.abort
    return if @current_mode.on_insert_at_cursor and @current_mode\on_insert_at_cursor(params, self)

    if @popup
      @popup.window\on_insert_at_cursor(self, params) if @popup.window.on_insert_at_cursor
    elseif args.text.ulen == 1
      config = @buffer.config
      return unless config.complete != 'manual'
      return unless #@current_context.word_prefix >= config.completion_popup_after
      skip_styles = config.completion_skip_auto_within
      if skip_styles
        cur_style = @current_context.style
        return if not cur_style
        for skip_style in *skip_styles
          return if cur_style\match skip_style

      @complete!
      true

  _on_delete_back: (_, args) =>
    if @popup
      params = text: args.text, editor: self, at_pos: @buffer\char_offset(args.pos)
      @popup.window\on_delete_back self, params if @popup.window.on_delete_back

-- Default indicators

with Editor
  .register_indicator 'title', 'top_left'
  .register_indicator 'position', 'bottom_right'
  .register_indicator 'activity', 'top_right', -> Gtk.Spinner!

-- Config variables

with config
  .define
    name: 'tab_width'
    description: 'The width of a tab, in number of characters'
    default: 4
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
    name: 'completion_skip_auto_within'
    description: 'Do not popup auto completions when inside these styles'
    default: nil
    type_of: 'string_list'
    options: {
      { 'string', 'Do not auto-complete within strings' },
      { 'comment', 'Do not auto-complete within comments' },
      { 'comment, string', 'Do not auto-complete within strings or comments' },
    }

  .define
    name: 'indentation_guides'
    description: 'Controls whether indentation guides are shown'
    default: 'on'
    options: {
      { 'none', 'No indentation guides are shown' }
      { 'on', 'Indentation guides are shown' }
    }

  .define
    name: 'edge_column'
    description: 'Shows an edge line at the specified column, if set'
    default: nil
    type_of: 'number'

  .define
    name: 'line_wrapping'
    description: 'Controls how lines are wrapped if neccessary'
    default: 'word'
    options: {
      { 'none', 'Lines are not wrapped' }
      { 'word', 'Lines are wrapped on word boundaries' }
      { 'character', 'Lines are wrapped on character boundaries' }
    }

  .define
    name: 'line_wrapping_navigation'
    description: 'Controls how wrapped lines are navigated'
    default: 'visual'
    options: {
      { 'real', 'Lines are navigated by real lines' }
      { 'visual', 'Lines are navigated by visual (wrapped) lines' }
    }

  .define
    name: 'line_wrapping_symbol'
    description: 'The symbol used for indicating a line wrap'
    type_of: 'string'
    default: '⏎'

  .define
    name: 'horizontal_scrollbar'
    description: 'Whether horizontal scrollbars are shown'
    default: true
    type_of: 'boolean'

  .define
    name: 'vertical_scrollbar'
    description: 'Whether vertical scrollbars are shown'
    default: true
    type_of: 'boolean'

  .define
    name: 'cursor_line_highlighted'
    description: 'Whether the cursor line is highlighted'
    default: true
    type_of: 'boolean'

  .define
    name: 'matching_braces_highlighted'
    description: 'Whether matching braces are highlighted'
    default: true
    type_of: 'boolean'

  .define
    name: 'line_numbers'
    description: 'Whether line numbers are shown'
    default: true
    type_of: 'boolean'

  .define
    name: 'cursor_blink_interval'
    description: 'The rate at which the cursor blinks (ms, 0 disables)'
    default: 500
    type_of: 'number'

  .define
    name: 'line_padding'
    description: 'Extra spacing above and below each line'
    default: 1
    type_of: 'number'

  .define
    name: 'undo_limit'
    description: 'Per buffer limit of undo revisions to keep'
    default: 100
    type_of: 'number'
    scope: 'global'

  for watched_property in *{
    'indentation_guides',
    'edge_column',
    'line_wrapping',
    'line_wrapping_navigation',
    'horizontal_scrollbar',
    'vertical_scrollbar',
    'cursor_line_highlighted',
    'line_numbers',
    'line_padding',
  }
    .watch watched_property, apply_property

  for live_update in *{
    { 'font', 'view_font_name' }
    { 'font_size', 'view_font_size' }
    { 'tab_width', 'view_tab_size' }
    { 'line_numbers', 'view_show_line_numbers' }
    { 'indent', 'view_indent' }
    { 'cursor_blink_interval', 'cursor_blink_interval' }
    { 'line_wrapping_symbol', 'view_line_wrap_symbol' }
  }
    .watch live_update[1], (_, value) -> apply_variable live_update[2], value


  for global_var in *{
    'undo_limit'
  }
    .watch global_var, apply_global_variable

-- Commands
for cmd_spec in *{
  { 'newline', 'Adds a new line at the current position', 'newline' }
  { 'comment', 'Comments the selection or current line', 'comment' }
  { 'uncomment', 'Uncomments the selection or current line', 'uncomment' }
  { 'toggle-comment', 'Comments or uncomments the selection or current line', 'toggle_comment' }
  { 'delete-line', 'Deletes the current line', 'delete_line' }
  { 'cut-to-end-of-line', 'Cuts to the end of line', 'delete_to_end_of_line' }
  { 'delete-to-end-of-line', 'Deletes to the end of line', 'delete_to_end_of_line', no_copy: true }
  { 'copy-line', 'Copies the current line to the clipboard', 'copy_line' }
  { 'paste', 'Pastes the contents of the clipboard at the current position', 'paste' }
  { 'smart-tab', 'Inserts tab or shifts selected text right', 'smart_tab' }
  { 'smart-back-tab', 'Moves to previous tab stop or shifts text left', 'smart_back_tab' }
  { 'delete-back', 'Deletes one character back', 'delete_back' }
  { 'delete-back-word', 'Deletes one word back', 'delete_back_word' }
  { 'delete-forward', 'Deletes one character forward', 'delete_forward' }
  { 'delete-forward-word', 'Deletes one word forward', 'delete_forward_word' }
  { 'shift-right', 'Shifts the selected lines, or the current line, right', 'shift_right' }
  { 'shift-left', 'Shifts the selected lines, or the current line, left', 'shift_left' }
  { 'indent', 'Indents the selected lines, or the current line', 'indent' }
  { 'indent-all', 'Indents the entire buffer', 'indent_all' }
  { 'join-lines', 'Joins the current line with the line below', 'join_lines' }
  { 'complete', 'Starts completion at cursor', 'complete' }
  { 'undo', 'Undo last edit for the current editor', 'undo' }
  { 'redo', 'Redo last undo for the current editor', 'redo' }
  { 'scroll-up', 'Scrolls one line up', 'scroll_up' }
  { 'scroll-down', 'Scrolls one line down', 'scroll_down' }
  { 'duplicate-current', 'Duplicates the selection or current line', 'duplicate_current' }
  { 'cut', 'Cuts the selection or current line to the clipboard', 'cut' }
  { 'copy', 'Copies the selection or current line to the clipboard', 'copy' }
  { 'cycle-case', 'Changes case for current word or selection', 'cycle_case' }
}
  args = { select 4, table.unpack cmd_spec }
  command.register
    name: "editor-#{cmd_spec[1]}"
    description: cmd_spec[2]
    handler: -> howl.app.editor[cmd_spec[3]] howl.app.editor, table.unpack args

for sel_cmd_spec in *{
  { 'select-all', 'Selects all text' }
}
  command.register
    name: "editor-#{sel_cmd_spec[1]}"
    description: sel_cmd_spec[2]
    handler: -> howl.app.editor.selection[sel_cmd_spec[1]\gsub '-', '_'] howl.app.editor.selection

-- signals

signal.register 'before-buffer-switch',
  description: 'Signaled right before a buffer is set for an editor'
  parameters:
    editor: 'The editor for which the buffer is being set'
    current_buffer: 'The current buffer for the editor'
    new_buffer: 'The new buffer that will be set for the editor'

signal.register 'after-buffer-switch',
  description: 'Signaled right after a buffer has been set for an editor'
  parameters:
    editor: 'The editor for which the buffer was set'
    current_buffer: 'The new buffer that was set for the editor'
    old_buffer: 'The buffer that was previously set for the editor'

signal.register 'editor-focused',
  description: 'Signaled right after an editor has recieved focus'
  parameters:
    editor: 'The editor that recieved focus'

signal.register 'editor-defocused',
  description: 'Signaled right after an editor has lost focus'
  parameters:
    editor: 'The editor that lost focus'

signal.register 'editor-destroyed',
  description: 'Signaled as an editor is destroyed'
  parameters:
    editor: 'The editor that is being destroyed'

signal.register 'insert-at-cursor',
  description: 'Signaled when text has been inserted into an editor at the cursor position'
  parameters:
    editor: 'The editor for which the text was inserted'
    text: 'The inserted text'

signal.register 'cursor-changed',
  description: 'Signaled when the cursor position has changed'
  parameters:
    editor: 'The editor for which the text was inserted'
    cursor: 'The cursor object'

return Editor
