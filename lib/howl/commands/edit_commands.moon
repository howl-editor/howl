-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, Buffer, command, interact, mode from howl
import BufferPopup from howl.ui

command.register
  name: 'buffer-search-forward',
  description: 'Starts an interactive forward search'
  input: ->
    if interact.forward_search!
      return true
    app.editor.searcher\cancel!
  handler: -> app.editor.searcher\commit!

command.register
  name: 'buffer-search-backward',
  description: 'Starts an interactive backward search'
  input: ->
    if interact.backward_search!
      return true
    app.editor.searcher\cancel!
  handler: -> app.editor.searcher\commit!

command.register
  name: 'buffer-search-word-forward',
  description: 'Jumps to next occurence of word at cursor'
  input: ->
    app.window.command_line\write_spillover app.editor.current_context.word.text
    if interact.forward_search_word!
      return true
    app.editor.searcher\cancel!
  handler: -> app.editor.searcher\commit!

command.register
  name: 'buffer-search-word-backward',
  description: 'Jumps to previous occurence of word at cursor'
  input: ->
    app.window.command_line\write_spillover app.editor.current_context.word.text
    if interact.backward_search_word!
      return true
    app.editor.searcher\cancel!
  handler: -> app.editor.searcher\commit!

command.register
  name: 'buffer-repeat-search',
  description: 'Repeats the last search'
  handler: -> app.editor.searcher\repeat_last!

command.register
  name: 'buffer-replace'
  description: 'Replaces text (within selection or globally)'
  input: ->
    buffer = app.editor.buffer
    chunk = app.editor.active_chunk
    replacement = interact.get_replacement
      title: 'Preview replacements for ' .. buffer.title
      editor: app.editor

    return replacement if replacement
    log.info "Cancelled - buffer untouched"

  handler: (replacement) ->
    if replacement.text
      buffer = app.editor.buffer
      app.editor\with_position_restored ->
        buffer\as_one_undo ->
          buffer.text = replacement.text
      log.info "Replaced #{replacement.num_replaced} instances"
    if replacement.cursor_pos
      app.editor.cursor.pos = replacement.cursor_pos
    if replacement.line_at_top
      app.editor.line_at_top = replacement.line_at_top

command.register
  name: 'buffer-replace-regex',
  description: 'Replaces text using regular expressions (within selection or globally)'
  input: ->
    buffer = app.editor.buffer
    chunk = app.editor.active_chunk
    replacement = interact.get_replacement_regex
      title: 'Preview replacements for ' .. buffer.title
      editor: app.editor

    return replacement if replacement
    log.info "Cancelled - buffer untouched"

  handler: (replacement) ->
    buffer = app.editor.buffer
    if replacement.text
      app.editor\with_position_restored ->
        buffer\as_one_undo ->
          buffer.text = replacement.text
      log.info "Replaced #{replacement.num_replaced} instances"
    if replacement.cursor_pos
      app.editor.cursor.pos = replacement.cursor_pos
    if replacement.line_at_top
      app.editor.line_at_top = replacement.line_at_top

command.register
  name: 'editor-paste..',
  description: 'Pastes a selected clip from the clipboard at the current position'
  input: interact.select_clipboard_item
  handler: (clip) -> app.editor\paste :clip

command.register
  name: 'show-doc-at-cursor',
  description: 'Shows documentation for symbol at cursor, if available'
  handler: ->
    ctx = app.editor.current_context
    m = app.editor.buffer\mode_at ctx.pos
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
  input: interact.select_mode
  handler: (selected_mode) ->
    buffer = app.editor.buffer
    buffer.mode = selected_mode
    log.info "Forced mode '#{selected_mode.name}' for buffer '#{buffer}'"

command.register
  name: 'cursor-goto-line'
  description: 'Go to the specified line'
  input: () ->
    line_str = interact.read_text title: 'Go to line'
    return tonumber line_str

  handler: (line_no) -> app.editor.cursor\move_to line: line_no, column: 1

command.register
  name: 'cursor-goto-brace'
  description: 'Go to the brace matching the current brace, if any'
  handler: ->
    cursor = app.editor.cursor
    pos = app.editor\get_matching_brace cursor.pos
    cursor\move_to(:pos, :extend) if pos

