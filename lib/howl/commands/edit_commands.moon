-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, Buffer, command, interact, mode from howl
import BufferPopup from howl.ui

command.register
  name: 'buffer-search-forward',
  description: 'Starts an interactive forward search'
  interactive: true
  handler: ->
    if interact.forward_search!
      app.editor.searcher\commit!
    else
      app.editor.searcher\cancel!

command.register
  name: 'buffer-search-backward',
  description: 'Starts an interactive backward search'
  interactive: true
  handler: ->
    if interact.backward_search!
      app.editor.searcher\commit!
    else
      app.editor.searcher\cancel!

command.register
  name: 'buffer-search-word-forward',
  description: 'Jumps to next occurence of word at cursor'
  interactive: true
  handler: ->
    app.window.command_line\write_spillover app.editor.current_context.word.text
    if interact.forward_search_word!
      app.editor.searcher\commit!
    else
      app.editor.searcher\cancel!

command.register
  name: 'buffer-search-word-backward',
  description: 'Jumps to previous occurence of word at cursor'
  interactive: true
  handler: ->
    app.window.command_line\write_spillover app.editor.current_context.word.text
    if interact.backward_search_word!
      app.editor.searcher\commit!
    else
      app.editor.searcher\cancel!

command.register
  name: 'buffer-repeat-search',
  description: 'Repeats the last search'
  handler: -> app.editor.searcher\repeat_last!

howl.command.register
  name: 'buffer-replace'
  description: 'Replaces text (within selection or globally)'
  interactive: true
  handler: ->
    buffer = app.editor.buffer
    chunk = app.editor.active_chunk
    result = interact.get_replacement
      title: 'Preview replacements for ' .. buffer.title
      editor: app.editor

    if result
      if result.text
        app.editor\with_position_restored ->
          buffer\as_one_undo ->
            buffer.text = result.text
        log.info "Replaced #{result.num_replaced} instances"
      if result.cursor_pos
        app.editor.cursor.pos = result.cursor_pos
      if result.line_at_top
        app.editor.line_at_top = result.line_at_top
    else
      log.info "Cancelled - buffer untouched"

command.register
  name: 'buffer-replace-regex',
  description: 'Replaces text using regular expressions (within selection or globally)'
  interactive: true
  handler: ->
    buffer = app.editor.buffer
    chunk = app.editor.active_chunk
    result = interact.get_replacement_regex
      title: 'Preview replacements for ' .. buffer.title
      editor: app.editor

    if result
      if result.text
        app.editor\with_position_restored ->
          buffer\as_one_undo ->
            buffer.text = result.text
        log.info "Replaced #{result.num_replaced} instances"
      if result.cursor_pos
        app.editor.cursor.pos = result.cursor_pos
      if result.line_at_top
        app.editor.line_at_top = result.line_at_top
    else
      log.info "Cancelled - buffer untouched"

command.register
  name: 'editor-paste..',
  description: 'Pastes a selected clip from the clipboard at the current position'
  interactive: true
  handler: ->
    clip = interact.select_clipboard_item!
    if clip
      app.editor\paste :clip

command.register
  name: 'show-doc-at-cursor',
  description: 'Shows documentation for symbol at cursor, if available'
  handler: ->
    m = app.editor.buffer.mode
    ctx = app.editor.current_context
    if m.api and m.resolve_type
      node = m.api
      path, parts = m\resolve_type ctx

      if path
        node = node[k] for k in *parts when node

      node = node[ctx.word.text] if node

      if node and node.description
        buf = Buffer mode.by_name('markdown')
        buf.text = node.description
        app.editor\show_popup BufferPopup buf
        return

    log.info "No documentation found for '#{ctx.word}'"

command.register
  name: 'buffer-mode',
  description: 'Sets a specified mode for the current buffer'
  interactive: true
  handler: ->
    selected_mode = interact.select_mode!
    return unless selected_mode
    buffer = app.editor.buffer
    buffer.mode = selected_mode
    log.info "Forced mode '#{selected_mode.name}' for buffer '#{buffer}'"
