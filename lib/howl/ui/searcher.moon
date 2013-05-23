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

  forward_to: (search) =>
    highlight.remove_all 'search', @editor.buffer

    pos = @editor.cursor.pos
    unless @active
      @_init!
      pos += 1

    start_pos, end_pos = @text\ufind search, pos, true

    if not start_pos and config.search_wraps
      start_pos, end_pos = @text\ufind search, 1, true
      if start_pos
        log.info 'Search hit BOTTOM, continuing at TOP'

    if start_pos
      @editor.cursor.pos = start_pos
      highlight.apply 'search', @editor.buffer, start_pos, (end_pos - start_pos) + 1
    else
      log.error "No matches found for '#{search}'"

    @last_search = search

  next: =>
    if @last_search
      log.info "Next match for '#{@last_search}'"
      @forward_to @last_search
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

