-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gdk = require 'ljglibs.gdk'
Gtk = require 'ljglibs.gtk'
aullar = require 'aullar'
gobject_signal = require 'ljglibs.gobject.signal'
import signal, bindings, config, command, clipboard, sys from howl
aullar_config = aullar.config
import PropertyObject from howl.util.moon
import Searcher, CompletionPopup from howl.ui
import auto_pair from howl.editing

{
  :IndicatorBar,
  :Cursor,
  :Selection,
  :ContentBox
} = howl.ui
{:max, :min} = math
append = table.insert

_editors = setmetatable {}, __mode: 'v'
editors = -> [e for _, e in pairs _editors when e != nil]

indicators = {}
indicator_placements =
  top_left: true
  top_right: true
  bottom_left: true
  bottom_right: true

editor_config_vars = {
  indentation_guides: 'indentation_guides'
  line_wrapping: 'line_wrapping'
  line_wrapping_navigation: 'line_wrapping_navigation'
  horizontal_scrollbar: 'horizontal_scrollbar'
  vertical_scrollbar: 'vertical_scrollbar'
  cursor_line_highlighted: 'cursor_line_highlighted'
  line_numbers: 'line_numbers'
  line_padding: 'line_padding'
  edge_column: 'edge_column'
}

aullar_config_vars = {
  cursor_blink_interval: 'cursor_blink_interval'
  scroll_speed_x: 'scroll_speed_x'
  scroll_speed_y: 'scroll_speed_y'
  indent: 'view_indent'
  tab_width: 'view_tab_size'
  font_name: 'view_font_name'
  font_size: 'view_font_size'
  line_wrapping_symbol: 'view_line_wrap_symbol'
}

apply_global_variable = (name, value) ->
  aullar_config[name] = value

apply_variable = (name) ->
  for e in *editors!
    e\refresh_variable name

signal.connect 'buffer-saved', (args) ->
  for e in *editors!
    e\remove_popup! if e.buffer == args.buffer

signal.connect 'buffer-title-set', (args) ->
  buffer = args.buffer
  for e in *editors!
    if buffer == e.buffer
      e.indicator.title.label = buffer.title

signal.connect 'buffer-mode-set', (args) ->
  buffer = args.buffer
  for e in *editors!
    if buffer == e.buffer
      e\_set_config_settings!

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
      on_button_release: self\_on_button_release
      on_motion_event: self\_on_motion_event
      on_focus_in: self\_on_focus
      on_focus_out: self\_on_focus_lost
      on_insert_at_cursor: self\_on_insert_at_cursor
      on_delete_back: self\_on_delete_back
      on_preedit_start: -> log.info "In pre-edit mode.."
      on_preedit_change: (_, args) ->
        log.info "Pre-edit: #{args.str} (Enter to submit, escape to cancel)"
      on_preedit_end: -> log.info "Pre-edit mode finished"
      on_scroll: self\_on_scroll

    @view.listener = listener
    @view.cursor.listener = {
      on_pos_changed: self\_on_pos_changed
    }

    @selection = Selection @view
    @cursor = Cursor self, @selection, drop_crumbs: true
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
      prev_buffer = @_buf
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

  @property mode_at_cursor: get: => @buffer\mode_at @cursor.pos
  @property config_at_cursor: get: => @buffer\config_at @cursor.pos

  refresh_display: => @view\refresh_display from_line: 1, invalidate: true
  grab_focus: => @view\grab_focus!
  newline: =>
    @buffer\as_one_undo ->
      @view\insert @buffer.eol

  shift_right: =>
    @with_selection_preserved ->
      @transform_active_lines (lines) ->
        for line in *lines
          line\indent!

  shift_left: =>
    @with_selection_preserved ->
      @transform_active_lines (lines) ->
        for line in *lines
          if line.indentation > 0
            line\unindent!

  transform_active_lines: (f) =>
    lines = @active_lines
    return if #lines == 0
    start_pos = lines[1].start_pos
    end_pos = lines[#lines].end_pos
    @buffer\change start_pos, end_pos, -> f lines

  with_position_restored: (f) =>
    line, column, indentation, top_line = @cursor.line, @cursor.column, @current_line.indentation, @line_at_top
    status, ret = pcall f, self
    @cursor.line = line
    delta = @current_line.indentation - indentation
    @cursor.column = max 1, column + delta
    @line_at_top = top_line
    error ret unless status

  with_selection_preserved: (f) =>
    if @selection.empty
      return f self

    start_offset, end_offset = @selection.anchor, @selection.cursor
    invert = start_offset > end_offset
    start_offset, end_offset = end_offset, start_offset if invert

    @buffer.markers\add {
      {
        name: 'howl-selection'
        :start_offset
        :end_offset
        preserve: true
      }
    }

    status, ret = pcall f, self

    markers = @buffer.markers\for_range 1, @buffer.length, name: 'howl-selection'
    @buffer.markers\remove name: 'howl-selection'

    marker = markers[1]
    if marker
      start_offset, end_offset = marker.start_offset, marker.end_offset
      start_offset, end_offset = end_offset, start_offset if invert
      @selection\set start_offset, end_offset

    error ret unless status

  preview: (buffer) =>
    unless @_is_previewing
      @_pre_preview_buffer = @buffer
      @_pre_preview_line_at_top = @line_at_top

    @_show_buffer buffer, preview: true

    signal.emit 'preview-opened', {
      editor: self,
      current_buffer: @_pre_preview_buffer,
      preview_buffer: buffer
    }

  cancel_preview: =>
    if @_is_previewing and @_pre_preview_buffer
      preview_buffer = @buffer
      @_show_buffer @_pre_preview_buffer
      @line_at_top = @_pre_preview_line_at_top
      @_pre_preview_buffer = nil

      signal.emit 'preview-closed', {
        editor: self,
        current_buffer: @buffer,
        :preview_buffer
      }

  indent: => @_apply_to_line_modes 'indent'

  indent_all: =>
    @with_position_restored ->
      @selection\select_all!
      @indent!

  comment: => @_apply_to_line_modes 'comment'
  uncomment: => @_apply_to_line_modes 'uncomment'
  toggle_comment: => @_apply_to_line_modes 'toggle_comment'

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
      text = clip.text
      trailing_eol = text\ends_with @buffer.eol

      if opts.where == 'after'
        if trailing_eol and line.next
          line = line.next
        else
          line = @buffer.lines\insert @current_line.nr + 1, ''
          if trailing_eol
            text = text\sub(1, -(#@buffer.eol + 1))

      elseif not trailing_eol
        line = @buffer.lines\insert line.nr, ''

      @cursor.pos = line.start_pos

      @with_position_restored ->
        @insert text

  insert: (text) => @view\insert text

  smart_tab: =>
    if not @selection.empty
      @shift_right!
      return

    conf = @config_at_cursor
    if conf.tab_indents and @current_context.prefix.is_blank
      cur_line = @current_line
      next_indent = cur_line.indentation + conf.indent
      next_indent -= (next_indent % conf.indent)
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

    conf = @config_at_cursor
    if conf.tab_indents and @current_context.prefix.is_blank
      cursor_col = @cursor.column
      cur_line = @current_line
      cur_line\unindent!
      @cursor.column = min(cursor_col, cur_line.indentation + 1)
    else
      return if @cursor.column == 1
      tab_stops = math.floor (@cursor.column - 1) / conf.tab_width
      col = tab_stops * conf.tab_width + 1
      col -= conf.tab_width if col == @cursor.column
      @cursor.column = col

  delete_back: =>
    prefix = @current_context.prefix
    if @selection.empty and prefix.is_blank and not prefix.is_empty
      if @config_at_cursor.backspace_unindents
        cur_line = @current_line
        gap = cur_line.indentation - @cursor.column
        cur_line\unindent!
        @cursor.column = max(1, cur_line.indentation - gap)
        return

    @view\delete_back allow_coalescing: true

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
    x, y = @_get_popup_coordinates options.position

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
    return if @completion_popup.active
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
      @line_at_top = max 1,  line - 2
    else
      @line_at_bottom = min #@buffer.lines, line + 2

  get_matching_brace: (pos, start_pos=1, end_pos=@buffer.length) =>
    byte_offset = @buffer\byte_offset
    pos = @_get_matching_brace(byte_offset(pos), byte_offset(start_pos), byte_offset(end_pos))
    return pos and @buffer\char_offset pos

  -- private
  _show_buffer: (buffer, opts={}) =>
    @selection\remove!
    @remove_popup!

    if @_buf
      @_buf.properties.position = @cursor.pos
      @_buf.properties.line_at_top = @line_at_top
      @_buf\remove_view_ref @view
      unless @_is_previewing
        @_buf.last_shown = sys.time!

    @_is_previewing = opts.preview
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

  refresh_variable: (name) =>
    value = @buffer.config[name]
    if aullar_config_vars[name]
      if @view.config[aullar_config_vars[name]] != value
        @view.config[aullar_config_vars[name]] = value
    elseif editor_config_vars[name]
      if @[editor_config_vars[name]] != value
        @[editor_config_vars[name]] = value
    else
      error "Invalid var #{name}"

  _set_config_settings: =>
    for name, _ in pairs editor_config_vars
      @refresh_variable name

    for name, _ in pairs aullar_config_vars
      @refresh_variable name

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
    y = def.placement\match('^(%w+)_%w+$')
    bar = y == 'top' and @header or @footer
    bar\remove id
    @indicator[id] = nil

  _apply_to_line_modes: (method) =>
    lines = @active_lines

    mode = nil
    modes = [@buffer\mode_at line.start_pos for line in *lines]
    mode = modes[1]
    for other_mode in *modes
      if mode != other_mode
        mode = @buffer.mode
        break

    mode[method] mode, self if mode[method]

  _pos_from_coordinates: (x, y) =>
    byte_offset = @view\position_from_coordinates(x, y)
    if byte_offset
      @buffer\char_offset byte_offset

  _word_or_token_at: (pos) =>
    context = @buffer\context_at pos
    chunk = context.word
    chunk = context.token if chunk.empty
    chunk

  _expand_to_word_token_boundaries: (pos1, pos2) =>
    chunk1 = @_word_or_token_at pos1
    chunk2 = if pos2
      @_word_or_token_at pos2
    else
      chunk1
    if pos1 <= pos2
      chunk1.start_pos, chunk2.end_pos + 1
    else
      chunk1.end_pos + 1, chunk2.start_pos

  _expand_to_line_starts: (pos1, pos2) =>
    line1 = @buffer.lines\at_pos(pos1)
    line2 = @buffer.lines\at_pos(pos2)
    if pos1 <= pos2
      line1.start_pos, @_next_line_start(line2)
    else
      @_next_line_start(line1), line2.start_pos

  _next_line_start: (line) =>
    next_line = line.next
    if next_line
      next_line.start_pos
    else
      line.end_pos

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

    maps = { @buffer.keymap, @mode_at_cursor and @mode_at_cursor.keymap }
    return true if bindings.process event, 'editor', maps, self

  _on_button_press: (view, event) =>
    return false if event.button == 3

    if event.button == 1
      @drag_press_type = event.type
      @drag_press_pos = @_pos_from_coordinates(event.x, event.y)

      if event.type == Gdk.GDK_2BUTTON_PRESS
        group = @current_context.word
        group = @current_context.token if group.empty

        unless group.empty
          @selection\set group.start_pos, group.end_pos + 1
          true

      elseif event.type == Gdk.GDK_3BUTTON_PRESS
        @selection\set @current_line.start_pos, @_next_line_start(@current_line)

    elseif event.button == 2
      text = clipboard.primary.text
      if text
        pos = @_pos_from_coordinates(event.x, event.y)
        @selection\remove!
        @cursor.pos = pos
        @insert text
        clipboard.primary.text = text

  _on_button_release: (view, event) =>
    @drag_press_type = nil

  _on_motion_event: (view, event) =>
    if @drag_press_type == Gdk.GDK_2BUTTON_PRESS or @drag_press_type == Gdk.GDK_3BUTTON_PRESS
      pos = @_pos_from_coordinates(event.x, event.y)
      if pos
        sel_start, sel_end = @drag_press_pos, pos
        if @drag_press_type == Gdk.GDK_2BUTTON_PRESS
          sel_start, sel_end = @_expand_to_word_token_boundaries sel_start, sel_end
        elseif @drag_press_type == Gdk.GDK_3BUTTON_PRESS
          sel_start, sel_end = @_expand_to_line_starts sel_start, sel_end

        unless sel_start == sel_end
          @selection\set sel_start, sel_end
          true

  _on_pos_changed: =>
    @_update_position!
    @_brace_highlight!
    if @popup and @popup.window.on_pos_changed
      @popup.window\on_pos_changed @cursor

    signal.emit 'cursor-changed', editor: self, cursor: @cursor

  _get_matching_brace: (byte_pos, start_pos, end_pos) =>
    buffer = @view.buffer
    return if byte_pos < 1 or byte_pos > buffer.size

    auto_pairs = @buffer\mode_at(buffer\char_offset byte_pos).auto_pairs
    return unless auto_pairs

    cur_char = buffer\sub byte_pos, byte_pos
    matching_close = auto_pairs[cur_char]

    local matching_open
    for k, v in pairs auto_pairs
      if v == cur_char
        matching_open = k
        break

    matching = matching_close or matching_open
    return unless matching and matching != cur_char

    if matching_close
        return buffer\pair_match_forward(byte_pos, matching_close, end_pos)
    else
        return buffer\pair_match_backward(byte_pos, matching_open, start_pos)

  _brace_highlight: =>
    return unless @view.showing

    {:buffer, :cursor} = @view

    if @_brace_highlighted
      buffer.markers\remove name: 'brace_highlight'
      @_brace_highlighted = false

    should_highlight = @config_at_cursor.matching_braces_highlighted
    return unless should_highlight
    auto_pairs = @mode_at_cursor.auto_pairs
    return unless auto_pairs

    highlight_braces = (pos1, pos2, flair) ->
      buffer.markers\add {
        {
          name: 'brace_highlight',
          :flair,
          start_offset: pos1,
          end_offset: pos1 + 1
        },
        {
          name: 'brace_highlight',
          :flair,
          start_offset: pos2,
          end_offset: pos2 + 1
        },
      }
      @_brace_highlighted = true

    pos = cursor.pos

    match_pos = @_get_matching_brace pos - 1
    if match_pos
      highlight_braces match_pos, pos - 1, 'brace_highlight_secondary'

    match_pos = @_get_matching_brace pos
    if match_pos
      highlight_braces match_pos, pos, 'brace_highlight'

  _update_position: =>
    pos = @cursor.line .. ':' .. @cursor.column
    @indicator.position.label = pos

  _get_popup_coordinates: (pos=@cursor.pos) =>
    pos = @buffer\byte_offset pos
    coordinates = @view\coordinates_from_position pos
    unless coordinates
      pos = @buffer.lines[@line_at_top].start_pos
      coordinates = @view\coordinates_from_position pos

    x = coordinates.x
    y = coordinates.y2 + 2
    x, y

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
    return if @mode_at_cursor.on_insert_at_cursor and @mode_at_cursor\on_insert_at_cursor(params, self)

    if @popup
      @popup.window\on_insert_at_cursor(self, params) if @popup.window.on_insert_at_cursor
    elseif args.text.ulen == 1
      config = @config_at_cursor
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

  _on_scroll: =>
    return unless @popup and @popup.showing
    x, y = @_get_popup_coordinates @popup.options.position
    @popup.window\move_to x, y

-- Default indicators

with Editor
  .register_indicator 'title', 'top_left'
  .register_indicator 'position', 'bottom_right'
  .register_indicator 'activity', 'top_right', -> Gtk.Spinner!
  .register_indicator 'inspections', 'bottom_left'

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
    name: 'scroll_speed_y'
    description: 'A percentage value determining the vertical mouse scrolling speed'
    default: 100
    type_of: 'number'

  .define
    name: 'scroll_speed_x'
    description: 'A percentage value determining the horizontal mouse scrolling speed'
    default: 100
    type_of: 'number'

  .define
    name: 'line_padding'
    description: 'Extra spacing above and below each line'
    default: 0
    type_of: 'number'

  .define
    name: 'undo_limit'
    description: 'Per buffer limit of undo revisions to keep'
    default: 100
    type_of: 'number'
    scope: 'global'

  for watched_property, _ in pairs aullar_config_vars
    .watch watched_property, apply_variable

  for watched_property, _ in pairs editor_config_vars
    .watch watched_property, apply_variable

  for global_var in *{
    'undo_limit'
  }
    .watch global_var, apply_global_variable

-- Commands
for cmd_spec in *{
  { 'newline', 'Add a new line at the current position', 'newline' }
  { 'comment', 'Comment the selection or current line', 'comment' }
  { 'uncomment', 'Uncomment the selection or current line', 'uncomment' }
  { 'toggle-comment', 'Comment or uncomment the selection or current line', 'toggle_comment' }
  { 'delete-line', 'Delete the current line', 'delete_line' }
  { 'cut-to-end-of-line', 'Cut to the end of line', 'delete_to_end_of_line' }
  { 'delete-to-end-of-line', 'Delete to the end of line', 'delete_to_end_of_line', no_copy: true }
  { 'copy-line', 'Copy the current line to the clipboard', 'copy_line' }
  { 'paste', 'Paste the contents of the clipboard at the current position', 'paste' }
  { 'smart-tab', 'Insert tab or shift selected text right', 'smart_tab' }
  { 'smart-back-tab', 'Move to previous tab stop or shifts text left', 'smart_back_tab' }
  { 'delete-back', 'Delete one character back', 'delete_back' }
  { 'delete-back-word', 'Delete one word back', 'delete_back_word' }
  { 'delete-forward', 'Delete one character forward', 'delete_forward' }
  { 'delete-forward-word', 'Delete one word forward', 'delete_forward_word' }
  { 'shift-right', 'Shift the selected lines, or the current line, right', 'shift_right' }
  { 'shift-left', 'Shift the selected lines, or the current line, left', 'shift_left' }
  { 'indent', 'Indent the selected lines, or the current line', 'indent' }
  { 'indent-all', 'Indent the entire buffer', 'indent_all' }
  { 'join-lines', 'Join the current line with the line below', 'join_lines' }
  { 'complete', 'Start completion at cursor', 'complete' }
  { 'undo', 'Undo last edit for the current editor', 'undo' }
  { 'redo', 'Redo last undo for the current editor', 'redo' }
  { 'scroll-up', 'Scroll one line up', 'scroll_up' }
  { 'scroll-down', 'Scroll one line down', 'scroll_down' }
  { 'duplicate-current', 'Duplicate the selection or current line', 'duplicate_current' }
  { 'cut', 'Cut the selection or current line to the clipboard', 'cut' }
  { 'copy', 'Copy the selection or current line to the clipboard', 'copy' }
  { 'cycle-case', 'Change case for current word or selection', 'cycle_case' }
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

signal.register 'preview-opened',
  description: 'Signaled right after a preview buffer was opened in an editor'
  parameters:
    editor: 'The editor for which the preview was opened'
    current_buffer: 'The current non-preview buffer associated with the editor'
    preview_buffer: 'The new preview buffer that is open in the editor'

signal.register 'preview-closed',
  description: 'Signaled right after a preview buffer has been removed for an editor'
  parameters:
    editor: 'The editor for which the preview was opened'
    current_buffer: 'The orignal buffer that was restored for the editor'
    preview_buffer: 'The preview buffer that was previously open in the editor'

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
