-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:dispatch} = howl
{:highlight, :HelpContext, :List, :ListWidget} = howl.ui
{:Preview} = howl.interactions.util
append = table.insert

count = (n, noun) -> n == 1 and "1 #{noun}" or "#{n} #{noun}s"

-- groups locations into one row per line, with the byte ranges of the
-- locations on it. A location continuing on later lines ends with its first.
rows_for = (locations) ->
  rows, by_line = {}, {}
  for loc in *locations
    key = "#{loc.file}:#{loc.line_nr}"
    row = by_line[key]
    unless row
      row = { loc[1], '', file: loc.file, line_nr: loc.line_nr, text: loc[2] or '', ranges: {} }
      by_line[key] = row
      append rows, row

    stop = loc.byte_end_column
    stop = #row.text + 1 if stop <= loc.byte_start_column
    append row.ranges, { loc.byte_start_column, stop }

  for row in *rows
    table.sort row.ranges, (a, b) -> a[1] < b[1]

  rows

-- shows the text of row with name in place of its ranges, highlighted
render = (row, name) ->
  text = row.text
  parts, highlights = {}, {}
  pos, size = 1, 0
  for {start, stop} in *row.ranges
    continue if start < pos
    before = text\sub pos, start - 1
    append parts, before
    append parts, name
    size += #before
    if #name > 0
      append highlights, { byte_start_column: size + 1, byte_end_column: size + #name + 1 }
    size += #name
    pos = stop

  append parts, text\sub(pos)
  row[2] = table.concat parts
  row.item_highlights = { nil, highlights, highlight: 'search_secondary' }

-- reads a new name for a symbol, listing the places to rename with the name
-- typed so far in them. `opts.load` returns those places as locations with
-- the text of their lines as the second column, and the one to select, or nil
-- and a message. It's called once the prompt is shown.
class RenameView
  new: (@opts) =>
    @rows = {}
    @status = { 'info', 'Finding the places to rename…' }

  init: (@command_line, opts = {}) =>
    @command_line.title = @opts.title
    @editor = howl.app.editor
    @previewer = Preview!
    @list = List (-> @rows), on_selection_change: (row) -> @_preview row
    @list.columns = { { style: 'comment' }, {} }
    @list_widget = ListWidget @list, never_shrink: true
    @list_widget.max_height_request = opts.max_height if opts.max_height
    @list_widget\hide!
    @command_line\add_widget 'locations', @list_widget
    dispatch.launch -> @_load!

  _load: =>
    status, locations, selected = pcall @opts.load
    return if @closed

    if not status
      @status = { 'error', locations }
    elseif not locations
      @status = { 'warning', selected or 'Found no places to rename' }
    else
      @rows = rows_for locations
      files = {}
      files[row.file.path] = true for row in *@rows
      nr_files = 0
      nr_files += 1 for _ in pairs files
      @status = { 'info', "#{count #locations, 'place'} in #{count nr_files, 'file'}" }
      @_refresh!
      if selected
        for row in *@rows
          if row.file == selected.file and row.line_nr == selected.line_nr
            @list.selection = row
            break

    @_show_status!

  _refresh: =>
    return if #@rows == 0
    name = @command_line.text
    render row, name for row in *@rows
    @list_widget\show!
    @list\update nil, true

  _show_status: =>
    with @command_line.notification
      \notify @status[1], @status[2]
      \show!

  _preview: (row) =>
    return unless row and @editor and @editor.preview
    buffer = @previewer\get_buffer row.file, row.line_nr
    @_clear_highlights!
    @editor\preview buffer
    line = buffer.lines[row.line_nr]
    return unless line
    @editor.line_at_center = row.line_nr
    for {start, stop} in *row.ranges
      start_pos = buffer\char_offset line.byte_start_pos + start - 1
      end_pos = buffer\char_offset line.byte_start_pos + stop - 1
      highlight.apply 'search', buffer, start_pos, end_pos - start_pos

    @highlighted = buffer

  _clear_highlights: =>
    highlight.remove_all 'search', @highlighted if @highlighted
    @highlighted = nil

  on_text_changed: =>
    @_refresh!
    @_show_status!

  get_help: =>
    with HelpContext!
      \add_keys {
        { enter: 'Rename to the entered name' }
        { up: 'Select the previous place, previewed in the editor' }
        { down: 'Select the next place, previewed in the editor' }
      }

  on_close: =>
    @closed = true
    @_clear_highlights!
    @editor\cancel_preview! if @editor and @editor.cancel_preview

  keymap:
    enter: => @command_line\finish @command_line.text
    escape: => @command_line\finish!

    binding_for:
      ['cursor-up']: => @list\select_prev!
      ['cursor-down']: => @list\select_next!
      ['cursor-page-up']: => @list\prev_page!
      ['cursor-page-down']: => @list\next_page!

-- returns the entered name, or nil if cancelled. opts are `title`, `text` (the
-- current name) and `load` (see RenameView).
read_name = (opts) ->
  howl.app.window.command_panel\run RenameView(opts), text: opts.text

:read_name
