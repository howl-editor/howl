import interact from howl

-- construct a search function suitable for SearchView from a general find(text, query, start) function
-- when called the search function returns an iterator of chunks
find_iterator = (opts) ->
  {:buffer, :lines, :find, :parse_query, :parse_line, :once_per_line} = opts
  local start_pos, end_pos
  if opts.chunk
    start_pos = opts.chunk and opts.chunk.start_pos or 1
    end_pos = opts.chunk and opts.chunk.end_pos or opts.buffer.length
    lines = buffer.lines\for_text_range start_pos, end_pos
  else
    start_pos = 1
    end_pos = buffer.length

  lines or= buffer.lines

  parsed_lines = {}  -- cached results of calling parse_line

  -- the search function
  (query) ->
    if parse_query
      query = parse_query query

    idx = 0
    inc_line = -> idx += 1
    get_line = -> lines[idx]
    get_parsed_line = ->
      parsed_line = parsed_lines[idx]
      unless parsed_line
        line = get_line!
        parsed_line = if parse_line then parse_line(line) else line
        parsed_lines[idx] = parsed_line
      parsed_line

    inc_line!
    line = get_line!
    search_start = if line.start_pos < start_pos then start_pos - line.start_pos + 1 else 1

    -- the iterator of chunks
    ->
      while line
        line_start = line.start_pos
        -- note we pass in the parsed line and parsed query to find
        match_start, match_end, match_info = find get_parsed_line!, query, search_start
        if match_start
          -- return a chunk for the matched segment
          return if line_start + match_end - 1 > end_pos  -- match beyond end_pos
          if once_per_line
            inc_line!
            line = get_line!
            search_start = 1
          else
            search_start = match_end + 1
          return buffer\chunk(line_start + match_start - 1, line_start + match_end - 1), match_info
        else
          inc_line!
          line = get_line!
          search_start = 1

interact.register
  name: 'buffer_search'
  description: 'Search and optionally replace within buffer'
  handler: (opts={}) ->
    error 'buffer required' unless opts.buffer
    error 'find function required' unless opts.find
    if opts.chunk and opts.lines
      error 'both chunk and lines cannot be specified'

    search = find_iterator(opts)

    search_view = howl.ui.SearchView
      editor: opts.editor or howl.app.editor
      buffer: opts.buffer
      prompt: opts.prompt
      title: opts.title
      search: search
      replace: opts.replace
      preview_lines: opts.lines or opts.buffer.lines
      preview_selected_line: opts.selected_line
      :search
      limit: opts.limit

    howl.app.window.command_panel\run search_view, text: opts.text, cancel_for_keymap: opts.cancel_for_keymap, help: opts.help
