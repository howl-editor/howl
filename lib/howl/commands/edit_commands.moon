-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:activities, :app, :breadcrumbs, :Buffer, :command, :interact, :mode} = howl
{:BufferPopup} = howl.ui
{:Process} = howl.io

command.register
  name: 'buffer-search-forward',
  description: 'Start an interactive forward search'
  input: ->
    if interact.forward_search!
      return true
    app.editor.searcher\cancel!
  handler: (commit) ->
    app.editor.searcher\commit! if commit

command.register
  name: 'buffer-search-backward',
  description: 'Start an interactive backward search'
  input: ->
    if interact.backward_search!
      return true
    app.editor.searcher\cancel!
  handler: (commit) ->
    app.editor.searcher\commit! if commit

command.register
  name: 'buffer-search-word-forward',
  description: 'Jump to next occurence of word at cursor'
  input: ->
    app.window.command_line\write_spillover app.editor.current_context.word.text
    if interact.forward_search_word!
      return true
    app.editor.searcher\cancel!
  handler: (commit) ->
    app.editor.searcher\commit! if commit

command.register
  name: 'buffer-search-word-backward',
  description: 'Jump to previous occurence of word at cursor'
  input: ->
    app.window.command_line\write_spillover app.editor.current_context.word.text
    if interact.backward_search_word!
      return true
    app.editor.searcher\cancel!
  handler: (commit) ->
    app.editor.searcher\commit! if commit

command.register
  name: 'buffer-repeat-search',
  description: 'Repeat the last search'
  handler: -> app.editor.searcher\repeat_last!

do_replacement = (replacement) ->
  editor = app.editor
  buffer = editor.buffer
  app.editor\with_position_restored ->
    buffer\as_one_undo ->
      buffer.text = replacement.text

  status = "Replaced #{replacement.num_replaced} instances"

  if editor.cursor.pos != replacement.cursor_pos
    breadcrumbs.drop!
    editor.cursor.pos = replacement.cursor_pos
    editor.line_at_top = replacement.line_at_top

  log.info status

command.register
  name: 'buffer-replace'
  description: 'Replace text (within selection or globally)'
  input: ->
    buffer = app.editor.buffer
    replacement = interact.get_replacement
      preview_title: 'Preview replacements for ' .. buffer.title
      editor: app.editor

    return replacement if replacement
    log.info "Cancelled - buffer untouched"

  handler: (replacement) ->
    do_replacement(replacement) if replacement.text

command.register
  name: 'buffer-replace-regex',
  description: 'Replace text using regular expressions (within selection or globally)'
  input: ->
    buffer = app.editor.buffer
    replacement = interact.get_replacement_regex
      title: 'Replace regex'
      preview_title: 'Preview replacements for ' .. buffer.title
      editor: app.editor

    return replacement if replacement
    log.info "Cancelled - buffer untouched"

  handler: (replacement) ->
    do_replacement(replacement) if replacement.text

command.register
  name: 'editor-paste..',
  description: 'Paste a selected clip from the clipboard at the current position'
  input: interact.select_clipboard_item
  handler: (clip) -> app.editor\paste :clip

command.register
  name: 'show-doc-at-cursor',
  description: 'Show documentation for symbol at cursor, if available'
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
        app.editor\show_popup BufferPopup buf, scrollable: true
        return

    log.info "No documentation found for '#{ctx.word}'"

command.register
  name: 'buffer-mode',
  description: 'Set a specified mode for the current buffer'
  input: -> interact.select_mode buffer: app.editor.buffer
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
    cursor\move_to(:pos) if pos

command.register
  name: 'editor-replace-exec'
  description: 'Replace selection with output of selection fed into external command'
  input: ->
    chunk = app.editor.active_chunk
    app.window.command_line.title = 'External command'
    working_directory, cmd = howl.interact.get_external_command!
    return unless working_directory
    return chunk, working_directory, cmd

  handler: (chunk, working_directory, cmd) ->
    process = Process.open_pipe cmd, :working_directory, stdin: chunk.text
    out, err = activities.run_process {title: 'Running filter'}, process
    if process.successful
      chunk.text = out
      log.info "Replaced with output of '#{cmd}'"
    else
      log.error "Failed to run #{cmd}: #{err or 'Unknown'}"

command.register
  name: 'editor-move-lines-up'
  description: 'Move current or selected lines up by one line'
  handler: ->
    editor = howl.app.editor
    buffer = editor.buffer
    lines = editor.active_lines
    first = lines[1].nr
    last = lines[#lines].nr
    return unless first > 1

    nr = first - 1
    text = buffer.lines[nr].text

    buffer\as_one_undo ->
      editor\with_selection_preserved ->
        buffer.lines\delete nr, nr
        buffer.lines\insert last, text

command.register
  name: 'editor-move-lines-down'
  description: 'Move current or selected lines down by one line'
  handler: ->
    editor = howl.app.editor
    buffer = editor.buffer
    lines = editor.active_lines
    first = lines[1].nr
    last = lines[#lines].nr
    return unless last < #buffer.lines

    nr = last + 1
    text = buffer.lines[nr].text

    buffer\as_one_undo ->
      editor\with_selection_preserved ->
        buffer.lines\delete nr, nr
        buffer.lines\insert first, text

command.register
  name: 'editor-move-text-right'
  description: 'Move selected text or current character right by one character'
  handler: ->
    editor = howl.app.editor
    buffer = editor.buffer
    start_pos, end_pos = editor.selection\range!
    unless start_pos
      start_pos = editor.cursor.pos
      end_pos = start_pos + 1

    return unless end_pos < #buffer

    buffer\as_one_undo ->
      editor\with_selection_preserved ->
        text = buffer\chunk(end_pos, end_pos).text
        buffer\delete end_pos, end_pos
        buffer\insert text, start_pos

command.register
  name: 'editor-move-text-left'
  description: 'Move selected text or current character left by one character'
  handler: ->
    editor = howl.app.editor
    buffer = editor.buffer
    start_pos, end_pos = editor.selection\range!
    unless start_pos
      start_pos = editor.cursor.pos
      end_pos = start_pos + 1

    return unless start_pos > 1

    buffer\as_one_undo ->
      editor\with_selection_preserved ->
        text = buffer\chunk(start_pos - 1, start_pos - 1).text
        buffer\insert text, end_pos
        buffer\delete start_pos - 1, start_pos - 1

command.register
  name: 'editor-newline-above'
  description: 'Add a new line above the current line'
  handler: ->
    editor = howl.app.editor
    buffer = editor.buffer
    cursor = editor.cursor

    buffer\as_one_undo ->
      cursor\home!
      editor\newline!
      cursor\up!
      editor\indent!

command.register
  name: 'editor-newline-below'
  description: 'Add a new line below the current line'
  handler: ->
    editor = howl.app.editor
    buffer = editor.buffer
    cursor = editor.cursor

    buffer\as_one_undo ->
      cursor\line_end!
      editor\newline!
