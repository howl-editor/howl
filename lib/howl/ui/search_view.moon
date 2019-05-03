-- Copyright 2019 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import ListWidget, List from howl.ui

append = table.insert

parse_query_for_replacement = (query) ->
  return if query.is_empty
  delimiter = query\usub(1, 1)
  pos = query\ufind delimiter, 2
  unless pos
    return query\usub(2), nil

  return query\usub(2, pos - 1), query\usub(pos + 1)

class BufferSearcher
  new: (opts) =>
    error 'search function missing' unless opts.search
    error 'buffer missing' unless opts.buffer

    @search_buffer = opts.buffer
    @search = opts.search -- search(query) -> iterator of Chunks
    @replace = opts.replace  -- replacement function
    @match_limit = opts.limit  -- max number of matches

    @reset!

  reset: =>
    @query = nil
    @query_pattern = nil
    @search_matches = {}  -- array of matches in @search_buffer
    @replacements = nil   -- map of search_match.id -> replacement_match
    @match_count = 0
    @partial = false  -- whether search was stopped before all matches were found
    @replacement_count = 0
    @replacement_text = nil

    buffer = howl.Buffer @search_buffer.mode
    buffer.title = 'Preview with replacements: ' .. @search_buffer.title
    @replacement_buffer = buffer

  run_query: (query, opts={}) =>
    -- process the query in a separate coroutine and call opts.on_error or .on_success
    -- if called when a query is still running, we cancel current query and launch a new coroutine
    @cancel_query!
    howl.dispatch.launch ->
      @running = howl.dispatch.park 'BufferSearcher.run_query'
      self.on_yield = opts.on_yield

      status, r = pcall -> @\handle_query query
      if @stop
        -- query was cancelled, clear flag and don't call callback
        @stop = false
      else
        -- query finished, call one of the callbacks
        pcall ->
          if status
            opts.on_success! if opts.on_success
          else
            opts.on_error(r) if opts.on_error

      running = @running
      @running = nil
      self.on_yield = nil
      howl.dispatch.resume running

  cancel_query: =>
    if @running
      @stop = true
      howl.dispatch.wait @running

  is_query_running: => @running != nil

  handle_query: (query) =>
    @query = query
    if @replace
      query_pattern, replacement = parse_query_for_replacement query
      @load_matches query_pattern
      @update_replacement_preview_buffer replacement
    else
      @load_matches query

    if @replace
      @set_status "Replacing #{@replacement_count} of #{@match_count} matches"
    else
      @set_status "#{@match_count} matches"

  load_matches: (query_pattern) =>
    @clear_replacements!
    return if query_pattern == @query_pattern
    @query_pattern = query_pattern

    -- when no query, we assume no matches
    if not query_pattern or query_pattern.is_empty
      @search_matches = {}
      @match_count = 0
      @partial = false
      return

    search = (query) ->
      -- handle nil, tables and iterators uniformly
      r = self.search query_pattern

      unless r
        -- convert nil to empty iterator
        return ->
      if type(r) == 'table'
        -- return iterator looping over table
        idx = 0
        return ->
          idx += 1
          r[idx]
      return r

    match_limit = @match_limit

    matches = {}
    count = 0
    partial = false

    -- chunk is a buffer chunk containing the match
    -- match_info is just an opaque object passed back into replace
    for chunk, match_info in search query_pattern
      break if not chunk
      count += 1
      append matches, id: count, start_pos: chunk.start_pos, end_pos: chunk.end_pos, :chunk, :match_info

      -- don't exceed total match limit
      if match_limit and count >= match_limit
        partial = true
        break
      break if partial

      -- update status every so often
      if math.fmod(count, 1000) == 0
        @set_status "Found #{count}..."
        @yield!

      if @stop
        partial = true
        break

    @progress_message = nil
    @search_matches = matches
    @match_count = count
    @partial = partial

  clear_replacements: =>
    @query_replacement = nil
    @replacement_count = 0
    @replacements = nil

  update_replacement_preview_buffer: (replacement) =>
    if replacement == nil
      @clear_replacements!
      @replacement_buffer.text = @search_buffer.text
      return

    @query_replacement = replacement
    @replacements = {}

    @apply_replacements replacement, preview: true
    with @replacement_buffer
      .text = @search_buffer\sub 1, @replacement_start_pos - 1
      \append @replacement_text
      \append @search_buffer\sub @replacement_end_pos + 1, @search_buffer.length

  apply_replacements: (replacement, opts={preview: true}) =>
    replace = self.replace

    replacement_text = {}
    replacement_length = 0
    replacement_append = (text, length) ->
      append replacement_text, text
      replacement_length += length

    all_replacements_start = 1
    last_match_end = 0  -- used to copy unmodified segments into replacement_text
    count = 0

    for match in *@search_matches
      replacement_append @search_buffer\sub(last_match_end + 1, match.start_pos - 1), (match.start_pos) - (last_match_end  + 1)

      chunk = match.chunk
      old_text = chunk.text
      -- new_text is the replacement text returned by the replace function
      new_text = if match.exclude then old_text else replace chunk, match.match_info, @query_pattern, replacement
      -- while previewing deleted text is displayed, otherwise it is deleted
      preview_text = if opts.preview and new_text.is_empty then old_text else new_text

      replacement_start = replacement_length + 1
      replacement_append preview_text, preview_text.ulen

      -- the start_pos and end_pos in the @replacements table represent positions in the new text (with replacements applied)
      @replacements[match.id] = {
        id: match.id
        start_pos: all_replacements_start + replacement_start - 1
        end_pos: all_replacements_start + replacement_length - 1
        deleted: new_text.is_empty
      }
      last_match_end = match.end_pos

      unless match.exclude
        count += 1

      if math.fmod(count, 1000) == 0
        @set_status "Loading #{count}..."
        @yield!

      return if @stop

    all_replacements_end = @search_buffer.length
    replacement_append @search_buffer\sub(last_match_end + 1, all_replacements_end), all_replacements_end - last_match_end

    @replacement_text = table.concat(replacement_text)
    @replacement_count = count
    @replacement_start_pos = all_replacements_start
    @replacement_end_pos = all_replacements_end

  toggle_replacement: (buffer, marker) =>
    search_match = @search_matches[marker.id]
    search_match.exclude = not search_match.exclude
    @update_replacement_preview_buffer @query_replacement
    @set_status "Replacing #{@replacement_count} of #{@match_count} matches"

  matches_for_range: (buffer, start_pos, end_pos) =>
    matches = {}
    active = false

    for match in *@search_matches
      match = if buffer == @search_buffer then match else @replacements[match.id]

      if active
        if match.end_pos <= end_pos
          append matches, match
        else
          break
      else
        if match.start_pos >= start_pos
          active = true
          append matches, match
    matches

  matches_as_rows: =>
    -- return items suitable for display in a list, one line per match
    rows = {}
    last_match = nil
    last_lnr = nil

    -- return matches with matched highlights
    for match in *@search_matches
      line = @search_buffer.lines\at_pos match.start_pos

      start_column = match.start_pos - line.start_pos + 1
      end_column = math.min(match.end_pos, line.end_pos) - line.start_pos + 2
      item_highlights = {
        {},
        {{:start_column, :end_column}},
        highlight: if self.replace and not match.exclude then 'replace_strikeout' else 'search_secondary'
      }

      -- show a continuation marker instead of line number for duplicated lines
      local display_lnr
      if last_lnr == line.nr
        display_lnr = '·'
      else
        display_lnr = line.nr
        last_lnr = line.nr

      last_match = {
        display_lnr,
        line.chunk,
        :line,
        buffer: if @replacements then @replacement_buffer else @search_buffer
        marker: if @replacements then @replacements[match.id] else match
        :item_highlights
      }
      append rows, last_match

    rows, @partial

  set_status: (message) => @status_message = message
  get_status: (message) => @status_message

  yield: =>
    if self.on_yield
      self.on_yield!
    howl.app\pump_mainloop!

  get_replacement: =>
    return unless @query_replacement
    @apply_replacements @query_replacement, preview: false
    {
      replacement_text: @replacement_text
      replacement_count: @replacement_count
      replacement_start_pos: @replacement_start_pos
      replacement_end_pos: @replacement_end_pos
    }

class SearchView
  new: (opts={}) =>
    error 'editor missing' unless opts.editor
    error 'search function missing' unless opts.search
    @opts = moon.copy opts
    @editor = opts.editor
    @searcher = nil -- holds a BufferSearcher object when a search is in progress
    @list_expanded = if opts.list_expanded == nil then true else opts.list_expanded

  init: (@command_line, opts) =>
    @command_line.title = @opts.title
    @command_line.prompt = @opts.prompt

    @searcher = BufferSearcher
      buffer: @opts.buffer
      search: @opts.search
      replace: @opts.replace
      limit: @opts.limit

    @max_height = opts.max_height
    @list = List nil,
      on_selection_change: @\select_match
    @list_widget = ListWidget @list, never_shrink: true

    @list.columns = {
      {style: 'comment', align: 'right', min_width: 4},
      {}
    }
    @command_line\add_widget 'matches', @list_widget
    @reset_list_size!

  set_buffer: (buffer) =>
    return if @buffer == buffer
    @buffer = buffer
    @editor\preview buffer

  on_text_changed: =>
    @refresh @command_line.text

  get_help: =>
    help = howl.ui.HelpContext!
    help\add_keys {
      {up: 'Select previous match'}
      {down: 'Select next match'}
      {ctrl_s: 'Toggle display of list of matches (lower panel)'}
    }

    if @opts.replace
      help\add_section
        heading: 'Syntax'
        text: 'Type <keyword>/</><string>pattern</><keyword>/</><string>replacement</> to replace pattern with replacement.
Start with a character other than <string>"/"</> to use it as the separator between the pattern and the replacement.'
      help\add_keys
        alt_enter: 'Toggle replacement for current match'
    help

  refresh: (query) =>
    if query.is_empty
      -- for no query, show all lines or opts.preview_lines
      -- note: blank replace queries still go to other branch because query == '/'
      @searcher\reset!

      with @command_line.notification
        \clear!
        \hide!

      buffer = @opts.buffer
      lines = if @opts.preview_lines then @opts.preview_lines else buffer.lines
      selected_line = @opts.preview_selected_line
      selected_row = nil

      rows = {}
      for line in *lines
        append rows, {line.nr, line.chunk, :buffer, marker: line.chunk}
        if selected_line == line
          selected_row = rows[#rows]

      @list.matcher = -> rows
      @list_widget\show!
      @list\update!
      @reset_list_size!
      -- set selected line, if provided
      if selected_row
        @list.selection = selected_row

    else
      -- fire the query on the searcher
      @searcher\run_query query,
          on_success: ->
            @show_status @searcher\get_status!

            -- refresh displayed list
            height_before_redraw = @list_widget.height
            @list_widget\show!
            @list.matcher = ->
              @searcher\matches_as_rows!
            @list\update!
            @reset_list_size!

            if #@list.items == 0 and @buffer
              -- usually select_match clears highlights, but with no items
              -- it wont be called
              @clear_highlights @buffer

            -- refreshing the list can make the editor smaller, in that case
            -- we want to re center the selected item back into view
            if @list_widget.height != height_before_redraw
              howl.timer.asap -> @select_match @list.selection

          on_error: (message) ->
            @show_error message

          on_yield: ->
            -- periodically update status
            @show_status @searcher\get_status!

  select_match: (selection) =>
    return unless selection
    buffer = selection.buffer
    @set_buffer buffer
    @clear_highlights buffer
    @highlight_buffer_for buffer, selection

  clear_highlights: (buffer) =>
    howl.ui.highlight.remove_all 'search_secondary', buffer
    howl.ui.highlight.remove_all 'search', buffer
    howl.ui.highlight.remove_all 'replace_strikeout', buffer

  highlight_buffer_for: (buffer, selection) =>
    marker = selection.marker

    line = buffer.lines\at_pos marker.start_pos
    @editor.line_at_center = line.nr

    highlighter_for_match = (match) -> if match.deleted then 'replace_strikeout' else 'search_secondary'

    -- highlight matches in the buffer, only visible ones as an optimization
    lines = buffer.lines
    visible_matches = @searcher\matches_for_range buffer, lines[@editor.line_at_top].start_pos, lines[@editor.line_at_bottom].end_pos
    for vmatch in *visible_matches
      howl.ui.highlight.apply highlighter_for_match(vmatch), buffer, {{vmatch.start_pos, vmatch.end_pos - vmatch.start_pos + 1}}

    -- deterine the currently selected match
    match = if selection.marker then selection.marker else selection.line.chunk

    -- remove the current highlight made for visible_matches and add a new highlight
    howl.ui.highlight.remove_in_range 'search_secondary', buffer, match.start_pos, match.end_pos
    howl.ui.highlight.apply 'search', buffer, {{match.start_pos, match.end_pos - match.start_pos + 1}}

  toggle_replacement: =>
    return if not @list.selection
    @searcher\toggle_replacement @list.selection.buffer, @list.selection.marker
    @list\update nil, true

  finish: (result) =>
    if result
      result.input_text = @command_line.text
    @command_line\finish result

  on_close: =>
    @editor\cancel_preview!
    @searcher\cancel_query!

  keymap:
    enter: =>
      if @opts.replace
        r = @searcher\get_replacement!
        @finish r
      else
        unless @list.selection
          @show_error 'No selection'
          return
        buffer = @list.selection.buffer
        marker = @list.selection.marker
        @finish chunk: buffer\chunk marker.start_pos, marker.end_pos

    escape: => @finish!

    alt_enter: => @toggle_replacement!

    binding_for:
      ['cursor-up']: => @list\select_prev!

      ['cursor-down']: => @list\select_next!

      ['cursor-page-up']: => @list\prev_page!

      ['cursor-page-down']: => @list\next_page!

    ctrl_s: => @toggle_list_expanded!

  reset_list_size: =>
    if @list_expanded and @max_height
      @list_widget.max_height_request = @max_height
      @list_widget\show!
    else
      @list_widget\hide!

  toggle_list_expanded: =>
    @list_expanded = not @list_expanded
    @reset_list_size!

  show_status: (message) =>
    with @command_line.notification
      \info message
      \show!

  show_error: (message) =>
    with @command_line.notification
      \error message
      \show!
