-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:activities, :app, :command, :interact, :timer} = howl
{:ActionBuffer, :BufferPopup, :MenuPopup, :markup} = howl.ui
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
    buffer = app.editor.buffer
    m = buffer\mode_at ctx.pos
    doc_buf = require('howl.lsp.hover').doc_for buffer, ctx.pos
    -- the server's response might arrive after switching to another buffer
    return if app.editor.buffer != buffer

    if not doc_buf and m.show_doc
      doc_buf = m\show_doc app.editor, ctx
    else if not doc_buf and m.api and m.resolve_type
      node = m.api
      path, parts = m\resolve_type ctx

      if path
        node = node[k] for k in *parts when node

      node = node[ctx.word.text] if node

      if node and node.description
        doc_buf = ActionBuffer!
        doc_buf\append markup.markdown(node.description)

    if doc_buf
      app.editor\show_popup BufferPopup doc_buf, scrollable: true
    else
     log.info "No documentation found for '#{ctx.word}'"

-- goes to the language server's locations from method for the symbol at the
-- cursor, letting you pick one if there are several, or calls fallback without
-- a language server's answer
goto_locations = (method, title, fallback) ->
  editor = app.editor
  buffer = editor.buffer
  locations = require('howl.lsp.definition').locations_for buffer, editor.cursor.pos, method
  -- the server's response might arrive after switching to another buffer
  return if app.editor.buffer != buffer

  unless locations
    fallback!
    return

  loc = if #locations == 1
    locations[1]
  else
    interact.select_location
      title: "#{title} of '#{editor.current_context.word}'"
      items: locations

  app\open loc if loc

command.register
  name: 'goto-definition',
  description: 'Go to the definition of the symbol at cursor'
  handler: ->
    goto_locations 'definition', 'Definitions', -> command.run 'project-file-search'

command.register
  name: 'goto-declaration',
  description: 'Go to the declaration of the symbol at cursor'
  handler: ->
    goto_locations 'declaration', 'Declarations', -> command.run 'goto-definition'

command.register
  name: 'goto-type-definition',
  description: 'Go to the definition of the type of the symbol at cursor'
  handler: ->
    goto_locations 'typeDefinition', 'Type definitions', ->
      log.info "No type definition found for '#{app.editor.current_context.word}'"

command.register
  name: 'goto-implementation',
  description: 'Go to an implementation of the symbol at cursor'
  handler: ->
    goto_locations 'implementation', 'Implementations', ->
      log.info "No implementation found for '#{app.editor.current_context.word}'"

command.register
  name: 'goto-reference',
  description: 'Go to a reference to the symbol at cursor'
  handler: ->
    editor = app.editor
    buffer = editor.buffer
    locations, at_cursor = require('howl.lsp.references').locations_for buffer, editor.cursor.pos
    -- the server's response might arrive after switching to another buffer
    return if app.editor.buffer != buffer

    -- without a language server's answer, search the project for the word
    unless locations
      command.run 'project-file-search'
      return

    loc = interact.select_location
      title: "#{#locations} references to '#{editor.current_context.word}'"
      items: locations
      selection: at_cursor

    app\open loc if loc

-- the targets offered by `goto`, with the server capability each needs
goto_targets = {
  { label: 'Definition', cmd: 'goto-definition', provider: 'definitionProvider' }
  { label: 'Declaration', cmd: 'goto-declaration', provider: 'declarationProvider' }
  { label: 'Type definition', cmd: 'goto-type-definition', provider: 'typeDefinitionProvider' }
  { label: 'Implementation', cmd: 'goto-implementation', provider: 'implementationProvider' }
  { label: 'References', cmd: 'goto-reference', provider: 'referencesProvider' }
}

command.register
  name: 'goto',
  description: 'Choose where to go for the symbol at cursor'
  handler: ->
    editor = app.editor
    buffer = editor.buffer
    state = require('howl.lsp').attach buffer
    unless state
      log.warn "No LSP server available for '#{buffer.title}'"
      return

    if editor.current_context.word.empty
      log.warn 'Please position the cursor on a symbol'
      return

    -- a server that's still starting hasn't told us what it supports yet
    client = state.client
    items = for t in *goto_targets
      continue if client.initialized and not client.capabilities[t.provider]
      { t.label, cmd: t.cmd }

    if #items == 0
      log.warn "The LSP server for '#{buffer.title}' supports no goto requests"
      return

    -- the command runs once the menu has closed, as it may open the command panel
    run_target = (item) ->
      timer.asap -> command.run item.cmd
      true

    editor\show_popup MenuPopup items, run_target

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
    app.editor.cursor\goto_matching_brace!

command.register
  name: 'editor-replace-exec'
  description: 'Replace selection with output of selection fed into external command'
  input: (opts) ->
    chunk = app.editor.active_chunk
    result = howl.interact.get_external_command!
    return unless result
    return chunk, result.working_directory, result.cmd

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
