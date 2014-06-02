-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import config from howl
import highlight from howl.ui

highlight.define_default 'search', {
  style: highlight.ROUNDBOX,
  color: '#ffffff'
  outline_alpha: 100
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
    @last_method = 'forward_to'

  forward_to: (search) => @jump_to search, 'forward'

  backward_to: (search) => @jump_to search, 'backward'

  jump_to: (search, direction = 'forward') =>
    highlight.remove_all 'search', @editor.buffer

    return if search.is_empty

    pos = @editor.cursor.pos

    if @active and direction == 'backward'
      -- allow active match to continue to match
      pos += #search - 1

    unless @active
      @_init!
      if direction == 'forward'
        pos += 1
      else
        -- match cannot start at pos but can overlap it
        pos += #search - 2

    find = nil
    wrap_pos = nil
    wrap_msg = ''

    if direction == 'forward'
      find = (text, search, pos) -> text\ufind search, pos, true
      wrap_pos = 1
      wrap_msg = 'Search hit BOTTOM, continuing at TOP'
    else
      find = (text, search, pos) -> text\urfind search, pos
      wrap_pos = -1
      wrap_msg = 'Search hit TOP, continuing at BOTTOM'

    start_pos, end_pos = find @text, search, pos

    if not start_pos and config.search_wraps
      start_pos, end_pos = find @text, search, wrap_pos
      if start_pos
        log.info wrap_msg

    if start_pos
      @editor.cursor.pos = start_pos
      highlight.apply 'search', @editor.buffer, start_pos, (end_pos - start_pos) + 1
    else
      log.error "No matches found for '#{search}'"

    @last_search = search
    @last_direction = direction

  next: =>
    if @last_direction == 'forward'
      @next_forward!
    else
      @next_backward!

  next_forward: =>
    if @last_search
      log.info "Next match for '#{@last_search}'"
      @forward_to @last_search
      @commit!

  next_backward: =>
    if @last_search
      log.info "Previous match for '#{@last_search}'"
      @backward_to @last_search
      @commit!

  commit: =>
    @text = nil
    @start_pos = nil
    @active = false

  cancel: =>
    highlight.remove_all 'search', @editor.buffer

    if @active
      @editor.cursor.pos = @start_pos
      @commit!

  _init: =>
    @start_pos = @editor.cursor.pos
    @text = @editor.buffer.text
    @active = true

