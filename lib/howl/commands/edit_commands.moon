-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:activities, :app, :Buffer, :command, :interact, :mode} = howl
{:BufferPopup} = howl.ui
{:Process} = howl.io

command.register
  name: 'buffer-search-forward',
  description: 'Start an interactive forward search'
  input: (opts) -> interact.forward_search prompt: opts.prompt, text: opts.text
  handler: (commit) ->
    app.editor.searcher\commit! if commit

command.register
  name: 'buffer-search-backward',
  description: 'Start an interactive backward search'
  input: (opts) -> interact.backward_search prompt: opts.prompt, text: opts.text
  handler: (commit) ->
    app.editor.searcher\commit! if commit

command.register
  name: 'buffer-search-word-forward',
  description: 'Jump to next occurence of word at cursor'
  input: (opts) ->
    current_word = app.editor.current_context.word.text or opts.text
    interact.forward_search_word prompt: opts.prompt, text: current_word
  handler: (commit) ->
    app.editor.searcher\commit! if commit

command.register
  name: 'buffer-search-word-backward',
  description: 'Jump to previous occurence of word at cursor'
  input: (opts) ->
    current_word = app.editor.current_context.word.text or opts.text
    interact.backward_search_word prompt: opts.prompt, text: current_word
  handler: (commit) ->
    app.editor.searcher\commit! if commit

command.register
  name: 'buffer-repeat-search',
  description: 'Repeat the last search'
  handler: -> app.editor.searcher\repeat_last!

selected_chunk = ->
  editor = app.editor
  return if editor.selection.empty
  start_pos, end_pos = editor.selection\range!
  editor.buffer\chunk start_pos, end_pos - 1

do_replacement = (replacement) ->
  editor = app.editor
  buffer = editor.buffer
  app.editor\with_position_restored ->
    buffer\as_one_undo ->
      buffer\chunk(replacement.replacement_start_pos, replacement.replacement_end_pos).text = replacement.replacement_text

  log.info "Replaced #{replacement.replacement_count} instances"

command.register
  name: 'buffer-replace'
  description: 'Replace text (within selection or globally)'
  input: (opts)->
    with opts.help
      \add_keys ctrl_r: 'Switch to <command_name>buffer-replace-regex</>'
      \add_keys enter: 'Apply all replacements'
    buffer = app.editor.buffer
    selection = selected_chunk!
    replacement = interact.buffer_search
      prompt: opts.prompt
      text: if not opts.text or opts.text.is_empty then '/' else opts.text
      help: opts.help
      title: "Replacements in #{buffer.title}"
      editor: app.editor
      :buffer
      find: (text, query, start) -> text\ufind query, start, true
      replace: (_, _, _, replacement) -> replacement
      chunk: selection
      cancel_for_keymap:
        ctrl_r: (args) ->
          if selection
            app.editor.selection\select selection.start_pos, selection.end_pos
          howl.command.run 'buffer-replace-regex ' .. args.text

    replacement

  handler: (replacement) ->
    do_replacement(replacement) if replacement

command.register
  name: 'buffer-replace-regex',
  description: 'Replace text using regular expressions (within selection or globally)'
  input: (opts) ->
    with opts.help
      \add_keys ctrl_h: 'Switch to <command_name>buffer-replace</>'
      \add_keys enter: 'Apply all replacements'
      \add_section
        header: ''
        text: 'The pattern uses PCRE syntax and replacement may contain backreferences such as <string>"\\1"</string>'
    buffer = app.editor.buffer
    selection = selected_chunk!
    replacement = interact.buffer_search
      prompt: opts.prompt
      text: if not opts.text or opts.text.is_empty then '/' else opts.text
      help: opts.help
      title: "Regex replacements in #{buffer.title}"
      editor: app.editor
      :buffer
      parse_line: (line) -> line.text
      parse_query: (query) ->
        status, query = pcall -> r query
        return query if status
        error 'Invalid regular expression', 0
      find: (text, regex, start) ->
        match = table.pack regex\find text, start
        captures = [match[idx + 2] for idx = 1, (regex.capture_count or 0)]
        match[1], match[2], captures
      replace: (chunk, match_info, query, replacement) ->
        captures = match_info
        result = replacement\gsub '(\\%d+)', (ref) ->
          ref_idx = tonumber(ref\sub(2))
          if ref_idx > 0
            return captures[ref_idx] or ''
          elseif ref_idx == 0
            return chunk.text
          return ''
        return result

      chunk: selection
      cancel_for_keymap:
        binding_for:
          'buffer-replace': (args) ->
            if selection
              app.editor.selection\select selection.start_pos, selection.end_pos
            howl.command.run 'buffer-replace ' .. args.text

    replacement

  handler: (replacement) ->
    do_replacement(replacement) if replacement

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
    local doc_buf

    if m.show_doc
      doc_buf = m\show_doc app.editor, ctx
    else if m.api and m.resolve_type
      node = m.api
      path, parts = m\resolve_type ctx

      if path
        node = node[k] for k in *parts when node

      node = node[ctx.word.text] if node

      if node and node.description
        doc_buf = Buffer mode.by_name('markdown')
        doc_buf.text = node.description

    if doc_buf
      app.editor\show_popup BufferPopup doc_buf, scrollable: true
    else
     log.info "No documentation found for '#{ctx.word}'"

command.register
  name: 'buffer-mode',
  description: 'Set a specified mode for the current buffer'
  input: (opts) -> interact.select_mode
    buffer: app.editor.buffer
    prompt: opts.prompt
    text: opts.text

  handler: (selected_mode) ->
    buffer = app.editor.buffer
    buffer.mode = selected_mode
    log.info "Forced mode '#{selected_mode.name}' for buffer '#{buffer}'"

command.register
  name: 'cursor-goto-line'
  description: 'Go to the specified line'
  input: (opts) ->
    line_str = interact.read_text prompt: opts.prompt, text: opts.text
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
  input: (opts) ->
    chunk = app.editor.active_chunk
    {:working_directory, :cmd} = howl.interact.get_external_command!
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
        editor\with_position_restored ->
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

    return unless end_pos <= #buffer

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
