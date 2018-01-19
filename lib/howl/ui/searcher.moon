-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:breadcrumbs, :config} = howl
{:highlight} = howl.ui

highlight.define_default 'search', {
  type: highlight.ROUNDED_RECTANGLE,
  foreground: '#ffffff'
  foreground_alpha: 100
}

highlight.define_default 'search_secondary', {
  type: highlight.ROUNDED_RECTANGLE,
  foreground: '#ffffff'
  foreground_alpha: 150
  background: '#ffffff'
  background_alpha: 0
}

with config
  .define
    name: 'search_wraps'
    description: 'Whether searches wrap around to top or bottom when there are no more matches'
    default: true
    type_of: 'boolean'

class Searcher
  new: (editor) =>
    @editor = editor
    @last_search = nil
    @last_direction = nil
    @last_type = nil

  forward_to: (search, type = 'plain', match_at_cursor = true) =>
    @jump_to search, direction: 'forward', type: type, match_at_cursor: match_at_cursor

  backward_to: (search, type = 'plain', match_at_cursor = @active) =>
    @jump_to search, direction: 'backward', type: type, match_at_cursor: match_at_cursor

  jump_to: (search, opts = {}) =>
    @_clear_highlights!
    return if search.is_empty

    direction = opts.direction or 'forward'
    ensure_word = opts.type == 'word'
    match_at_cursor = opts.match_at_cursor or false

    unless @active
      @_init!

    if direction == 'forward' and ensure_word
      -- back up to start of current word
      @editor.cursor.pos = @editor.current_context.word.start_pos

    init = @editor.cursor.pos

    if direction == 'forward'
      if not match_at_cursor
        init += 1
    else
      init += search.ulen - 2
      if match_at_cursor
        init += 1

    start_pos, end_pos = @_find_match search, init, direction, ensure_word

    if start_pos
      @editor.cursor.pos = end_pos
      @editor.cursor.pos = start_pos
      @_highlight_matches search, start_pos, ensure_word
    else
      if ensure_word
        log.error "No word matches found for '#{search}'"
      else
        log.error "No matches found for '#{search}'"

    @last_search = search
    @last_direction = direction
    @last_type = opts.type

  repeat_last: =>
    @_init!
    if @last_direction == 'forward'
      @next!
    else
      @previous!
    @commit!

  next: =>
    if @last_search
      if @last_type == 'word'
        log.info "Next match for word '#{@last_search}'"
      else
        log.info "Next match for '#{@last_search}'"
      @forward_to @last_search, @last_type, false

  previous: =>
    if @last_search
      if @last_type == 'word'
        log.info "Previous match for word '#{@last_search}'"
      else
        log.info "Previous match for '#{@last_search}'"
      @backward_to @last_search, @last_type, false

  commit: =>
    if @active
      if @start_pos != @editor.cursor.pos
        breadcrumbs.drop {
          buffer: @buffer,
          pos: @start_pos,
          line_at_top: @start_line_at_top
        }

      @_finish!

  cancel: =>
    @_clear_highlights!

    if @active
      @editor.cursor.pos = @start_pos
      @editor.line_at_top = @start_line_at_top
      @_finish!

  _finish: =>
    @buffer = nil
    @start_pos = nil
    @start_line_at_top = nil
    @active = false

  _find_match: (search, init, direction, ensure_word) =>
    finder = nil
    wrap_pos = nil
    wrap_msg = ''

    if direction == 'forward'
      finder = @buffer.find
      wrap_pos = 1
      wrap_msg = 'Search hit BOTTOM, continuing at TOP'
    else
      finder = @buffer.rfind
      wrap_pos = -1
      wrap_msg = 'Search hit TOP, continuing at BOTTOM'

    wrapped = false
    while true
      start_pos, end_pos = finder @buffer, search, init
      if start_pos
        if not ensure_word or @_is_word(start_pos, search)
          return start_pos, end_pos
        -- the match wasn't a word, continue searching
        if direction == 'forward'
          init = end_pos + 1
        else
          init = start_pos - 1
      else
        if wrapped or init == wrap_pos
          -- already wrapped, or no need to wrap
          return
        else
          init = wrap_pos
          log.info wrap_msg
          wrapped = true

  _is_word: (match_pos, word) =>
      match_ctx = @editor.buffer\context_at match_pos
      return match_ctx.word.text == word

  _highlight_matches: (search, match_pos, ensure_word) =>
    return unless search
    buffer = @editor.buffer

    -- scan the displayed lines and a few more for good measure
    start_boundary = buffer.lines[math.max(1, @editor.line_at_top - 5)].start_pos
    end_boundary = buffer.lines[math.min(#buffer.lines, @editor.line_at_bottom + 5)].end_pos
    ranges = {}

    -- match at match_pos gets a different highlight than other matches
    for start_pos, end_pos in @_find_matches search, start_boundary, end_boundary
      if not ensure_word or @_is_word(start_pos, search)
        if start_pos != match_pos
          ranges[#ranges + 1] = { start_pos, end_pos - start_pos + 1 }

    highlight.apply 'search', buffer, match_pos, search.ulen
    highlight.apply 'search_secondary', buffer, ranges

  _find_matches: (search, start_boundary, end_boundary) =>
    match_start_pos = nil
    match_end_pos = nil
    text = @buffer\sub start_boundary, end_boundary
    init = 1
    return ->
      while true
        if init > #text
          return

        match_start_pos, match_end_pos = text\ufind search, init, true
        return if not match_start_pos

        init = match_end_pos + 1

        return match_start_pos + start_boundary - 1, match_end_pos + start_boundary - 1

  _clear_highlights: =>
    highlight.remove_all 'search', @editor.buffer
    highlight.remove_all 'search_secondary', @editor.buffer

  _init: =>
    @start_pos = @editor.cursor.pos
    @start_line_at_top = @editor.line_at_top
    @buffer = @editor.buffer
    @active = true

