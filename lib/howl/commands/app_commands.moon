-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, activities, breadcrumbs, Buffer, command, config, bindings, bundle, interact, signal, mode, Project from howl
import ActionBuffer, JournalBuffer, ProcessBuffer, BufferPopup, StyledText from howl.ui
import Process from howl.io

serpent = require 'serpent'

get_project_root = ->
  buffer = app.editor and app.editor.buffer
  file = buffer.file or buffer.directory
  error "No file associated with the current view" unless file
  project = Project.get_for_file file
  error "No project associated with #{file}" unless project
  return project.root

belongs_to_project = (buffer, project_root) ->
  file = buffer.file or buffer.directory
  return false unless file
  project = Project.for_file file
  return false unless project
  return project.root == project_root

get_buffer_dir = (buffer) ->
  return unless buffer
  buffer.file and buffer.file.parent or buffer.directory

command.register
  name: 'quit',
  description: 'Quit the application'
  handler: -> howl.app\quit!

command.alias 'quit', 'q'

command.register
  name: 'save-and-quit',
  description: 'Save modified buffers and quit the application'
  handler: ->
    with howl.app
      \quit! if \save_all!

command.alias 'save-and-quit', 'wq'

command.register
  name: 'quit-without-save',
  description: 'Quit the application, disregarding any modified buffers'
  handler: -> howl.app\quit true

command.alias 'quit-without-save', 'q!'

command.register
  name: 'run'
  description: 'Run a command'
  handler: command.run

command.register
  name: 'new-buffer',
  description: 'Opens a new buffer'
  handler: ->
    breadcrumbs.drop!
    app.editor.buffer = howl.app\new_buffer!

command.register
  name: 'switch-buffer',
  description: 'Switch to another buffer'
  input: (opts) ->
    interact.select_buffer
      prompt: opts.prompt
      text: opts.text
      help: opts.help
  handler: (buf) ->
    breadcrumbs.drop!
    app.editor.buffer = buf

command.register
  name: 'project-switch-buffer',
  description: 'Switch to another buffer in current project'
  input: (opts) ->
    project_root = get_project_root!
    return unless project_root
    interact.select_buffer
      get_buffers: -> [buf for buf in *app.buffers when belongs_to_project buf, project_root]
      title: "Buffers under #{project_root}"
      prompt: opts.prompt
      text: opts.text
      help: opts.help
  handler: (buf) ->
    breadcrumbs.drop!
    app.editor.buffer = buf

command.register
  name: 'buffer-reload',
  description: 'Reload the current buffer from file'
  handler: ->
    buffer = app.editor.buffer
    if buffer.modified
      unless interact.yes_or_no prompt: 'Buffer is modified, reload anyway? '
        log.info "Not reloading; buffer is untouched"
        return

    buffer\reload true
    log.info "Buffer reloaded from file"

command.register
  name: 'switch-to-last-hidden-buffer',
  description: 'Switch to the last active hidden buffer'
  handler: ->
    for buffer in *howl.app.buffers
      if not buffer.showing
        breadcrumbs.drop!
        app.editor.buffer = buffer
        return

    _G.log.error 'No hidden buffer found'

command.register
  name: 'set',
  description: 'Set a configuration variable'
  input: (opts) ->
    interact.get_variable_assignment
      prompt: opts.prompt
      text: opts.text
      help: opts.help
  handler: (result) -> result.config_value\commit!
  get_input_text: (result) -> result.text

command.register
  name: 'describe-key',
  description: 'Show information for a key'
  handler: ->
    buffer = ActionBuffer!
    buffer.title = 'Key watcher'
    buffer\append 'Press any key to show information for it (press escape to quit)..\n\n', 'string'
    editor = howl.app\add_buffer buffer
    editor.cursor\eof!

    bindings.capture (event, source, translations) ->
      buffer.lines\delete 3, #buffer.lines
      buffer\append 'Key translations (usable from bindings):\n', 'comment'
      buffer\append serpent.block translations, comment: false
      buffer\append '\n\nKey event:\n', 'comment'
      buffer\append serpent.block event, comment: false
      bound_commands = {}
      for t in *translations
        cmd = bindings.action_for t
        cmd = '<function>' if typeof(cmd) == 'function'
        bound_commands[t] = cmd
      buffer\append '\n\nBound command:\n', 'comment'
      buffer\append serpent.block bound_commands, comment: false

      if event.key_name == 'escape'
        buffer.lines[1] = '(Snooping done, close this buffer at your leisure)'
        buffer\style 1, #buffer, 'comment'
        buffer.modified = false
      else
        return false

command.register
  name: 'describe-signal',
  description: 'Describe a given signal'
  input: interact.select_signal
  handler: (signal_name) ->
    def = signal.all[signal_name]
    error "Unknown signal '#{signal_name}'" unless def
    buffer = with ActionBuffer!
      .title = "Signal: #{signal_name}"
      \append "#{def.description}\n\n"
      \append "Parameters:"

    params = def.parameters
    if not params
      buffer\append "None"
    else
      buffer\append '\n\n'
      buffer\append StyledText.for_table [ { name, desc } for name, desc in pairs params ], {
        { header: 'Name', style: 'string'},
        { header: 'Description', style: 'comment' }
      }

    buffer.read_only = true
    buffer.modified = false
    howl.app\add_buffer buffer

command.register
  name: 'bundle-unload'
  description: 'Unload a specified bundle'
  input: interact.select_loaded_bundle
  handler: (name) ->
    log.info "Unloading bundle '#{name}'.."
    bundle.unload name
    log.info "Unloaded bundle '#{name}'"

command.register
  name: 'bundle-load'
  description: 'Load a specified, currently unloaded, bundle'
  input: interact.select_unloaded_bundle
  handler: (name) ->
    log.info "Loading bundle '#{name}'.."
    bundle.load_by_name name
    log.info "Loaded bundle '#{name}'"

command.register
  name: 'bundle-reload'
  description: 'Reload a specified bundle'
  input: interact.select_loaded_bundle
  handler: (name) ->
    log.info "Reloading bundle '#{name}'.."
    bundle.unload name if _G.bundles[name]
    bundle.load_by_name name
    log.info "Reloaded bundle '#{name}'"

command.register
  name: 'bundle-reload-current'
  description: 'Reload the last active bundle (with files open)'
  handler: ->
    for buffer in *app.buffers
      bundle_name = buffer.file and bundle.from_file(buffer.file) or nil
      if bundle_name
        command.bundle_reload bundle_name
        return

    log.warn 'Could not find any currently active bundle to reload'

matcher_find = (entry, matcher, start) ->
  -- entry is result of parse_line and matcher is result of parse_query
  how, positions = matcher entry.text, entry.case_text
  if how
    -- return start, end for the matched segment within the line
    return positions[1], positions[#positions]

command.register
  name: 'buffer-grep'
  description: 'Show buffer lines containing fuzzy matches in real time'
  input: (opts) ->
    buffer = app.editor.buffer
    opts.help\add_keys
      ['buffer-grep']: 'Switch to <command>buffer-grep-regex</>'
    return interact.buffer_search
      title: "Matches in #{buffer.title}"
      once_per_line: true
      limit: 1000
      parse_query: (query) -> howl.util.Matcher.create_matcher query
      parse_line: (line) -> {:line, case_text: line.text, text: line.text.ulower}
      find: matcher_find
      prompt: opts.prompt
      text: opts.text
      help: opts.help
      editor: app.editor
      buffer: buffer
      selected_line: app.editor.current_line
      cancel_for_keymap:
        binding_for:
          ['buffer-grep']: (args) -> howl.command.run 'buffer-grep-regex ' .. args.text

  handler: (result) ->
    return unless result
    breadcrumbs.drop!
    app.editor.cursor\move_to pos: result.chunk.start_pos

command.register
  name: 'buffer-grep-regex'
  description: 'Show buffer lines containing regex matches in real time'
  input: (opts) ->
    buffer = app.editor.buffer
    opts.help\add_keys
      ['buffer-grep']: 'Switch to <command>buffer-grep-exact</>'
      ['buffer-replace']: 'Switch to <command>buffer-replace-regex</>'
    return interact.buffer_search
      title: "Regex matches in #{buffer.title}"
      once_per_line: true
      limit: 1000
      parse_query: (query) ->
        status, query = pcall -> r query
        return query if status
        error 'Invalid regular expression', 0
      parse_line: (line) -> line.text
      find: (text, regex, start) -> regex\find text, start
      prompt: opts.prompt
      text: opts.text
      help: opts.help
      editor: app.editor
      buffer: buffer
      selected_line: app.editor.current_line
      cancel_for_keymap:
        binding_for:
          ['buffer-grep']: (args) -> howl.command.run 'buffer-grep-exact ' .. args.text
          ['buffer-replace']: (args) -> howl.command.run 'buffer-replace-regex /' .. args.text

  handler: (result) ->
    return unless result
    breadcrumbs.drop!
    app.editor.cursor\move_to pos: result.chunk.start_pos

command.register
  name: 'buffer-grep-exact'
  description: 'Show buffer lines containing exact matches in real time'
  input: (opts)->
    buffer = app.editor.buffer
    opts.help\add_keys
      ['buffer-grep']: 'Switch to <command>buffer-grep</>'
      ['buffer-replace']: 'Switch to <command>buffer-replace</>'
    return interact.buffer_search
      title: "Exact matches in #{buffer.title}"
      once_per_line: true
      limit: 1000
      parse_line: (line) -> line.text
      find: (text, query, start) -> text\ufind query, start, true
      prompt: opts.prompt
      text: opts.text
      help: opts.help
      editor: app.editor
      buffer: buffer
      selected_line: app.editor.current_line
      cancel_for_keymap:
        binding_for:
          ['buffer-grep']: (args) -> howl.command.run 'buffer-grep ' .. args.text
          ['buffer-replace']: (args) -> howl.command.run 'buffer-replace /' .. args.text

  handler: (result) ->
    return unless result
    breadcrumbs.drop!
    app.editor.cursor\move_to pos: result.chunk.start_pos

command.register
  name: 'buffer-structure'
  description: 'Show the structure for the current buffer'
  input: (opts) ->
    buffer = app.editor.buffer
    lines = buffer.mode\structure app.editor
    cursor_lnr = app.editor.cursor.line
    local selected_line
    for line in *lines
      if line.nr <= cursor_lnr
        selected_line = line
      if line.nr >= cursor_lnr
        break

    return interact.buffer_search
      title: "Structure for #{buffer.title}"
      once_per_line: true
      editor: app.editor
      buffer: buffer
      parse_query: (query) -> howl.util.Matcher.create_matcher query
      parse_line: (line) -> {:line, case_text: line.text, text: line.text.ulower}
      find: matcher_find
      prompt: opts.prompt
      text: opts.text
      help: opts.help
      :lines
      :selected_line

  handler: (result) ->
    return unless result
    breadcrumbs.drop!
    app.editor.cursor\move_to pos: result.chunk.start_pos

command.register
  name: 'navigate-back'
  description: 'Goes back to the last location recorded'
  handler: ->
    if breadcrumbs.previous
      breadcrumbs.go_back!
      log.info "navigate: now at #{breadcrumbs.location} of #{#breadcrumbs.trail}"
    else
      log.info "No previous location recorded"

command.register
  name: 'navigate-forward'
  description: 'Goes to the next location recorced'
  handler: ->
    if breadcrumbs.next
      breadcrumbs.go_forward!
      log.info "navigate: now at #{breadcrumbs.location} of #{#breadcrumbs.trail}"
    else
      log.info "No next location recorded"

command.register
  name: 'navigate-go-to'
  description: 'Goes to a specific location in the history'
  input: (opts) ->
    to_item = (crumb, i) ->
      {:buffer_marker, :file} = crumb
      buffer = buffer_marker and buffer_marker.buffer
      project = file and Project.for_file(file)
      where = if project
        file\relative_to_parent(project.root)
      elseif file
          file.path
      else
        buffer.title

      pos = breadcrumbs.crumb_pos crumb
      {
        i,
        project and project.root.basename or ''
        "#{where}@#{pos}"
        :buffer, :file, :pos
      }

    crumbs = breadcrumbs.trail
    items = [to_item(b, i) for i, b in ipairs crumbs]

    if #items == 0
      log.warn "No locations available for navigation"
      return nil

    interact.select_location
      title: "Navigate back to.."
      prompt: opts.prompt
      text: opts.text
      :items
      selection: items[breadcrumbs.location] or items[breadcrumbs.location - 1]
      columns: {
        { header: 'Position', style: 'number' },
        { header: 'Project', style: 'key' },
        { header: 'Path', style: 'string' }
      }

  handler: (loc) ->
    return unless loc
    breadcrumbs.location = loc[1]

command.register
  name: 'open-journal'
  description: 'Opens the Howl log journal'
  handler: ->
    app\add_buffer JournalBuffer!
    app.editor.cursor\eof!

-----------------------------------------------------------------------
-- Howl eval commands
-----------------------------------------------------------------------

do_howl_eval = (load_f, mode_name, transform_f) ->
  editor = app.editor
  text = editor.selection.empty and editor.current_line.text or editor.selection.text
  text = transform_f and transform_f(text) or text

  f = assert load_f text
  ret = { pcall f }
  if ret[1]
    out = ''
    for i = 2, #ret
      out ..= "\n#{serpent.block ret[i], comment: false}"

    if editor.popup
      log.info "(Eval) => #{ret[2]}"
    else
      buf = Buffer mode.by_name mode_name
      buf.text = "-- Howl eval (#{mode_name}) =>#{out}"
      editor\show_popup BufferPopup buf, scrollable: true
    howl.clipboard.push out
  else
    log.error "(ERROR) => #{ret[2]}"

command.register
  name: 'howl-lua-eval'
  description: 'Eval the current line or selection as Lua and copy result to clipboard'
  handler: ->
    do_howl_eval load, 'lua', (text) ->
      unless text\match 'return%s'
        text = if text\find '\n'
          text\gsub "\n([^\n]+)$", "\n  return %1"
        else
          "return #{text}"
      text

command.register
  name: 'howl-moon-eval'
  description: 'Eval the current line or selection as Moonscript and copy result to clipboard'
  handler: ->
    moonscript = require('moonscript')
    transform = (text) ->
      initial_indent = text\match '^([ \t]*)%S'
      if initial_indent -- remove the initial indent from all lines if any
        lines = [l\gsub("^#{initial_indent}", '') for l in text\gmatch('[^\n]+')]
        text = table.concat lines, '\n'

      moonscript.loadstring text

    do_howl_eval transform, 'moonscript'

command.register
  name: 'howl-moon-print'
  description: 'Compile and show the Lua for the current buffer or selection'
  handler: ->
    moonscript = require('moonscript.base')
    editor = app.editor
    buffer = editor.buffer
    title = "#{buffer.title} (compiled to Lua)"
    text = buffer.text

    unless editor.selection.empty
      title = "#{buffer.title} (Lua - from selection)"
      text = editor.selection.text

    lua, err = moonscript.to_lua text
    local buf
    if not lua
      buf = ActionBuffer!
      buf\append howl.ui.markup.howl "<error>#{err}</error>"
    else
      buf = Buffer mode.by_name 'lua'
      buf.text = lua

    buf.title = title
    buf.modified = false

    if #buf.lines > 20
      breadcrumbs.drop!
      editor.buffer = buf
    else
      buf\insert "-- #{title}\n", 1
      editor\show_popup BufferPopup buf, scrollable: true

-----------------------------------------------------------------------
-- Launch commands
-----------------------------------------------------------------------

launch_cmd = (working_directory, cmd) ->
  shell = howl.sys.env.SHELL or '/bin/sh'
  p = Process {
    :cmd,
    :shell,
    read_stdout: true,
    read_stderr: true,
    working_directory: working_directory,
  }

  breadcrumbs.drop!
  buffer = ProcessBuffer p
  editor = app\add_buffer buffer
  editor.cursor\eof!
  buffer\pump!

get_project = ->
  buffer = app.editor and app.editor.buffer
  file = buffer.file or buffer.directory
  error "No file associated with the current view" unless file
  project = Project.get_for_file file
  error "No project associated with #{file}" unless project
  return project

command.register
  name: 'project-exec',
  description: 'Run an external command from within the project directory'
  input: (opts) -> interact.get_external_command path: get_project_root!, prompt: opts.prompt
  handler: (args) -> launch_cmd args.working_directory, args.cmd
  get_input_text: (args) -> args.cmd

command.register
  name: 'project-build'
  description: 'Run the command in config.project_build_command from within the project directory'
  handler: -> launch_cmd get_project!.root, (app.editor and app.editor.buffer.config or config).project_build_command

command.register
  name: 'exec',
  description: 'Run an external command'
  input: (opts) -> interact.get_external_command
    path: get_buffer_dir howl.app.editor.buffer
    text: opts.text
  handler: (args) -> launch_cmd args.working_directory, args.cmd
  get_input_text: (args) -> args.cmd

command.register
  name: 'save-config'
  description: 'Save the current configuration'
  handler: ->
    config.save_config!
    log.info 'Configuration saved'

config.define
  name: 'project_build_command'
  description: 'The command to execute when project-build is run'
  default: 'make'
  type_of: 'string'

-----------------------------------------------------------------------
-- File search commands
-----------------------------------------------------------------------

config.define
  name: 'file_search_hit_display'
  description: 'How to display file search hits in the list'
  default: 'rich'
  type_of: 'string'
  options: -> {
    {'plain', 'Display as plain unicolor strings'},
    {'highlighted', 'Highlight search terms in hits'} ,
    {'rich', 'Show syntax highlighted snippets with highlighted terms'},
  }

file_search_hit_mt = {
  __tostyled: (item) ->
    text = item.text
    m = mode.for_file(item.match.file)
    if m and m.lexer
      styles = m.lexer(text)
      return StyledText text, styles

    text

  __tostring: (item) -> item.text
}

file_search_hit_to_location = (match, search, display_as) ->
  hit_display = if display_as == 'rich'
    setmetatable {text: match.message, :match}, file_search_hit_mt
  else
    match.message

  path = match.path\truncate(50, omission_prefix: '..')
  loc = {
    howl.ui.markup.howl "<comment>#{path}</>:<number>#{match.line_nr}</>"
    hit_display,
    file: match.file,
    line_nr: match.line_nr,
    column: match.column
  }
  search = search.ulower
  s, e = match.message.ulower\ufind(search, 1, true)
  unless s
    s, e = match.message\ufind((r(search)))

  if loc.column
    loc.byte_start_column = loc.column
    loc.byte_end_column = loc.column + #search
  elseif s
    loc.start_column = s
    loc.end_column = e + 1

  if s and display_as != 'plain'
    loc.item_highlights = {
      nil,
      {
        {byte_start_column: s, count: e - s + 1}
      }
    }

  loc

do_search = (search, whole_word) ->
  project = get_project!
  file_search = howl.file_search
  matches, searcher = file_search.search project.root, search, :whole_word
  unless #matches > 0
    log.error "No matches found for '#{search}'"
    return matches

  matches = file_search.sort matches, project.root, search, app.editor.current_context
  display_as = project.config.file_search_hit_display
  status = "Loaded 0 out of #{#matches} locations.."
  cancel = false
  locations = activities.run {
    title: "Loading #{#matches} locations..",
    status: -> status
    cancel: -> cancel = true
  }, ->
    return for i = 1, #matches
      if i % 1000 == 0
        break if cancel
        status = "Loaded #{i} out of #{#matches}.."
        activities.yield!

      m = matches[i]
      file_search_hit_to_location(m, search, display_as)

  locations, searcher, project

command.register
  name: 'project-file-search',
  description: 'Searches files in the the current project'
  input: (opts) ->
    editor = app.editor
    search = nil
    whole_word = false

    if opts.text and not opts.text.is_empty
      search = opts.text

    unless search or app.window.command_panel.is_active
      if editor.selection.empty
        search = app.editor.current_context.word.text
        whole_word = true unless search.is_empty
      else
        search = editor.selection.text

    if not search or search.is_empty
      search = interact.read_text prompt: opts.prompt

    if not search or search.is_empty
      log.warn "No search query specified"
      return

    locations, searcher, project = do_search search, whole_word
    if #locations > 0
      interact.select_location
        title: "#{#locations} matches for '#{search}' in #{project.root.short_path} (using #{searcher.name} searcher)"
        items: locations

  handler: (loc) ->
    if loc
      app\open loc

command.register
  name: 'project-file-search-list',
  description: 'Searches files in the the current project, listing results in a buffer'
  input: (opts) ->
    editor = app.editor
    search = nil
    whole_word = false

    if opts.text and not opts.text.is_empty
      search = opts.text

    unless app.window.command_panel.is_active
      if editor.selection.empty
        search = app.editor.current_context.word.text
        whole_word = true unless search.is_empty
      else
        search = editor.selection.text

    if not search or search.is_empty
      search = interact.read_text prompt: opts.prompt

    if not search or search.is_empty
      log.warn "No search query specified"
      return

    locations, searcher, project = do_search search , whole_word

    if #locations > 0
      matcher = howl.util.Matcher locations
      list = howl.ui.List matcher
      list_buf = howl.ui.ListBuffer list, {
        title: "#{#locations} matches for '#{search}' in #{project.root.short_path} (using #{searcher.name} searcher)"
        on_submit: (location) ->
          app\open location
      }
      list_buf.directory = project.root
      app\add_buffer list_buf

    nil

  handler: (loc) ->
