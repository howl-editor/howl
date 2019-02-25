-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import Window, Editor, theme from howl.ui
import Buffer, Settings, mode, breadcrumbs, bundle, bindings, keymap, signal, interact, timer, clipboard, config from howl
import File, Process from howl.io
import PropertyObject from howl.util.moon
Gtk = require 'ljglibs.gtk'
GFile = require 'ljglibs.gio.file'
callbacks = require 'ljglibs.callbacks'
{:get_monotonic_time} = require 'ljglibs.glib'
{:C} = require('ffi')
bit = require 'bit'

append = table.insert
coro_create, coro_status = coroutine.create, coroutine.status

non_idle_dispatches = {
  '^signal motion%-',
  '^signal key%-press%-event',
  '^signal button%-',
}

is_idle_dispatch = (desc) ->
  for p in *non_idle_dispatches
    return false if desc\find(p) != nil
  true

last_activity = get_monotonic_time!

dispatcher = (f, description, ...) ->

  unless is_idle_dispatch(description)
    last_activity = get_monotonic_time!

  co = coro_create (...) -> f ...
  status, ret = coroutine.resume co, ...

  if status
    if coro_status(co) == 'dead'
      return ret
  else
    error ret

  false

sort_buffers = (buffers, current_buffer=nil) ->
  table.sort buffers, (a, b) ->
    if current_buffer == a return true
    if current_buffer == b return false
    return true if a.showing and not b.showing
    return false if b.showing and not a.showing
    -- if none of the buffers are showing, we compare the last shown time
    unless a.showing
      ls_a = a.last_shown or 0
      ls_b = b.last_shown or 0
      return ls_a > ls_b if ls_a != ls_b
    a.title < b.title

parse_path_args = (paths, cwd=nil) ->
  files = {}
  hints = {}

  for path in *paths
    local file
    line, col = 1, 1

    e_path, s_line, s_col = path\match '^(.+):(%d+):(%d+)$'
    if e_path
      file = e_path
      line = tonumber s_line
      col = s_col
    else
      e_path, s_line = path\match '^(.+):(%d+)$'
      if e_path
        file = e_path
        line = tonumber s_line
      else
        file = path

    files[#files + 1] = File(file, cwd).gfile
    hints[#hints + 1] = "#{line}:#{col}"

  files, hints

class Application extends PropertyObject
  title: 'Howl'

  new: (@root_dir, @args) =>
    @windows = {}
    @_editors = {}
    @_buffers = {}
    @_recently_closed = {}
    bundle.dirs = { @root_dir / 'bundles' }
    @_load_base!
    bindings.push keymap
    @window = nil
    @editor = nil

    callbacks.configure {
      :dispatcher,
      on_error: _G.log.error
    }

    signal.connect 'log-entry-appended', (entry) ->
      level = entry.level
      message = entry.message
      return if level == 'traceback'

      if @window and @window.visible
        essentials = entry.essentials

        status = @window.status
        command_line = @window.command_line
        status[level] status, essentials
        command_line\notify essentials, level if command_line.showing
      elseif not @args.spec
        print message

    super!

  @property idle: get: =>
    tonumber(get_monotonic_time! - last_activity) / 1000 / 1000

  @property buffers: get: =>
    buffers = { table.unpack @_buffers }
    sort_buffers buffers, (@editor and @editor.buffer)
    buffers

  @property recently_closed: get: => moon.copy @_recently_closed

  @property editors: get: => @_editors

  @property next_buffer: get: =>
    return @new_buffer! if #@_buffers == 0

    sort_buffers @_buffers
    hidden_buffers = [b for b in *@_buffers when not b.showing]
    return #hidden_buffers > 0 and hidden_buffers[1] or @_buffers[1]

  new_window: (properties = {}) =>
    props = title: @title
    props[k] = v for k, v in pairs(properties)
    window = Window props
    window\set_default_size 800, 640

    window\on_delete_event ->
      if #@windows == 1
        modified = [b for b in *@_buffers when b.modified]
        if #modified > 0
          -- postpone the quit check, since we really need to prevent
          -- the close right away by returning true
          timer.asap -> @quit!
        else
          @quit!

        true

    window\on_destroy (destroy_window) ->
      @windows = [w for w in *@windows when w\to_gobject! != destroy_window]

    @g_app\add_window window\to_gobject!

    append @windows, window
    @window = window if #@windows == 1
    window

  new_editor: (opts = {}) =>
    editor = Editor opts.buffer or @next_buffer
    (opts.window or @window)\add_view editor, opts.placement or 'right_of'
    append @_editors, editor
    editor\grab_focus!
    editor

  editor_for_buffer: (buffer) =>
    for visible_editor in *@_editors
      if visible_editor.buffer == buffer
        return visible_editor

    nil

  new_buffer: (buffer_mode) =>
    buffer_mode or= mode.by_name 'default'
    buffer = Buffer buffer_mode
    @_append_buffer buffer
    buffer

  add_buffer: (buffer, show = true) =>
    for b in *@buffers
      return if b == buffer

    @_append_buffer buffer
    if show and @editor
      breadcrumbs.drop!
      @editor.buffer = buffer
      @editor

  close_buffer: (buffer, force = false) =>
    unless force
      local prompt
      if buffer.modified
        prompt = "Buffer is modified, close anyway? "
      elseif buffer.activity and buffer.activity\is_running!
        prompt = "Buffer has a running activity (#{buffer.activity.name}), close anyway? "

      if prompt
        return unless interact.yes_or_no :prompt

    @_buffers = [b for b in *@_buffers when b != buffer]

    if buffer.file
      @_add_recently_closed buffer

    if buffer.showing
      for editor in *@editors
        if editor.buffer == buffer
          if editor == @editor -- if showing in the current editor
            breadcrumbs.drop! -- we drop a crumb here

          editor.buffer = @next_buffer

    signal.emit 'buffer-closed', :buffer

  open_file: (file, editor = @editor) =>
    @open :file, editor

  open: (loc, editor) =>
    return unless loc
    unless loc.buffer or loc.file
      error "Malformed loc: either .buffer or .file must be set", 2

    file = loc.file
    buffer = loc.buffer or @_buffer_for_file(file)

    if buffer
      @add_buffer buffer
    else
      -- open the file specified
      buffer = @new_buffer mode.for_file file
      status, err = pcall -> buffer.file = file
      if not status
        @close_buffer buffer
        error "Failed to open #{file}: #{err}"

      @_recently_closed = [file_info for file_info in *@_recently_closed when file_info.file != buffer.file]
      signal.emit 'file-opened', :file, :buffer

    -- all right, now we got a buffer, let's get an editor if needed
    unless editor
      editor = @editor_for_buffer(loc.buffer) or @editor
      editor or= @new_editor buffer

    -- buffer and editor in place, drop a crumb and show the location
    breadcrumbs.drop {
      buffer: editor.buffer,
      pos: editor.cursor.pos,
      line_at_top: editor.line_at_top
    }

    editor.buffer = buffer

    if loc.line_nr
      editor.line_at_center = loc.line_nr
      opts = line: loc.line_nr
      if loc.column
        opts.column = loc.column
      elseif loc.column_index
        opts.column_index = loc.column_index

      editor.cursor\move_to opts

      if loc.highlights
        for hl in *loc.highlights
          editor\highlight hl, loc.line_nr

    -- drop another breadcrumb at the new location
    breadcrumbs.drop!

    buffer, editor

  save_all: =>
    for b in *@buffers
      if b.modified
        unless b.file
          log.error "No file associated with modified buffer '#{b}'"
          return false

        b\save!

    true

  synchronize: =>
    clipboard.synchronize!

    reload_count = 0
    changed_count = 0

    for b in *@_buffers
      if b.modified_on_disk
        changed_count += 1
        unless b.modified
          b\reload!
          reload_count += 1

    if changed_count > 0
      msg = "Files modified on disk: #{reload_count} buffer(s) reloaded"
      stale_count = changed_count - reload_count
      if stale_count > 0
        log.warn "#{msg}, #{stale_count} modified buffer(s) left"
      else
        log.info msg

  run: =>
    jit.off true, true
    args = @args
    app_base = 'io.howl.Editor'
    flags = bit.bor(
      Gtk.Application.HANDLES_OPEN,
      Gtk.Application.HANDLES_COMMAND_LINE
    )
    @g_app = Gtk.Application app_base, flags
    @g_app\register!

    -- by default we'll not open files in the same instance,
    -- but this can be toggled via the --reuse command line parameter
    if @g_app.is_remote and not @args.reuse
      @g_app = Gtk.Application "#{app_base}-#{os.time!}", bit.bor(
        flags,
        Gtk.Application.NON_UNIQUE
      )
      @g_app\register!

    @g_app\on_activate ->
      @_load!

    @g_app\on_open (_, files, hint) ->
      hints = [h for h in hint\gmatch '[^,]+']
      @_load files, hints

    @g_app\on_command_line (app, command_line) ->
      paths = [v for v in *command_line.arguments[2, ] when not v\match('^-')]
      files, hints = parse_path_args paths, command_line.cwd
      if #files > 0
        app\open files, table.concat(hints, ',')
      else
        app\activate!

    signal.connect 'window-focused', self\synchronize
    signal.connect 'editor-destroyed', (s_args) ->
      @_editors =  [e for e in *@_editors when e != s_args.editor]

    breadcrumbs.init!

    @g_app\run args

  quit: (force = false) =>
    if force or not @_should_abort_quit!
      unless #@args > 1
        @save_session!

        if config.save_config_on_exit
          unless pcall config.save_config
            print 'Error saving config'

      for _, process in pairs Process.running
        process\send_signal 'KILL'

      for win in * moon.copy @windows
        win.command_line\abort_all!
        win\destroy!

      howl.clipboard.store!

  save_session: =>
    return if @args.no_profile or #@args > 1

    session = {
      version: 1
      buffers: {}
      recently_closed: {}
      window: {
        maximized: @window.maximized
        fullscreen: @window.fullscreen
      }
    }

    for b in *@buffers
      continue unless b.file
      append session.buffers, {
        file: b.file.path
        last_shown: b.last_shown
        properties: b.properties
      }

    for f in *@_recently_closed
      append session.recently_closed, {
        file: f.file.path
        last_shown: f.last_shown
      }

    @settings\save_system 'session', session

  pump_mainloop: (max_count = 100) =>
    jit.off true, true
    count = 0
    ctx = C.g_main_context_default!
    while count < max_count and C.g_main_context_iteration(ctx, false) != 0
      count += 1

  _append_buffer: (buffer) =>
    if config.autoclose_single_buffer and #@_buffers == 1
      present = @_buffers[1]
      if not present.file and not present.modified and present.length == 0
        @_buffers[1] = buffer
        return

    append @_buffers, buffer

  _buffer_for_file: (file) =>
    for b in *@buffers
      return b if b.file == file

    nil

  _load: (files = {}, hints = {}) =>
    local window

    -- bootstrap if we're booting up
    unless @_loaded
      @settings = Settings!
      @_load_core!
      if @settings.dir
        append bundle.dirs, @settings.dir\join 'bundles'
        fonts_dir = @settings.dir\join('fonts')
        if fonts_dir.exists
          C.FcConfigAppFontAddDir(nil, fonts_dir.path)
      if howl.sys.info.is_flatpak
        append bundle.dirs, File '/app/bundles'

      bundle.load_all!

      unless @args.no_profile
        status, ret = pcall @settings.load_user, @settings
        unless status
          log.error "Failed to load user settings: #{ret}"

      theme.apply!
      @_load_application_icon!

      signal.connect 'mode-registered', self\_on_mode_registered
      signal.connect 'mode-unregistered', self\_on_mode_unregistered

      window = @new_window!

      howl.janitor.start!

    -- load files from command line
    loaded_buffers = {}
    for i = 1, #files
      file = File files[i]
      buffer = @_buffer_for_file file

      unless buffer
        buffer = @new_buffer mode.for_file file
        status, ret = pcall -> buffer.file = file
        if not status
          @close_buffer buffer
          buffer = nil
          log.error "Failed to open file '#{file}': #{ret}"

      if buffer
        hint = hints[i]
        if hint
          nums =  [tonumber(v) for v in hint\gmatch('%d+')]
          {line, column} = nums
          buffer.properties.position = :line, :column

        append loaded_buffers, buffer

    -- files we've loaded via a --reuse invocation should be shown
    if #loaded_buffers > 0 and @_loaded
      for i = 1, math.min(#@editors, #loaded_buffers)
        @editors[i].buffer = loaded_buffers[i]

    -- all loaded files should be considered as having been viewed just now
    now = howl.sys.time!
    for b in *loaded_buffers
      b.last_shown = now

    -- restore session properties
    unless @_loaded
      unless @args.no_profile
        @_restore_session window, #files == 0

    if #@editors == 0
      @editor = @new_editor @_buffers[1] or @new_buffer!

    for b in *loaded_buffers
      signal.emit 'file-opened', file: b.file, buffer: b

    unless @_loaded
      window\show_all! if window
      @_loaded = true
      howl.io.File.async = true
      signal.emit 'app-ready'
      @_set_initial_status window

  _should_abort_quit: =>
    modified = [b for b in *@_buffers when b.modified]
    if #modified > 0
      if not interact.yes_or_no prompt: "Modified buffers exist, close anyway? "
        return true

    false

  _on_mode_registered: (args) =>
    -- check if any buffers with default_mode could use this new mode
    default_mode = mode.by_name 'default'
    for buffer in *@_buffers
      if buffer.file and buffer.mode == default_mode
        buffer_mode = mode.for_file buffer.file
        if mode != default_mode
          buffer.mode = buffer_mode

  _on_mode_unregistered: (args) =>
    -- remove the mode from any buffers that are previously using it
    mode_name = args.name
    default_mode = mode.by_name 'default'
    for buffer in *@_buffers
      if buffer.mode.name == mode_name
        if buffer.file
          buffer.mode = mode.for_file buffer.file
        else
          buffer.mode = default_mode

  _restore_session: (window, restore_buffers) =>
    session = @settings\load_system 'session'

    if session and session.version == 1
      if restore_buffers
        for entry in *session.buffers
          file = File(entry.file)
          continue unless file.exists
          status, err = pcall ->
            buffer = @new_buffer mode.for_file file
            buffer.file = file
            buffer.last_shown = entry.last_shown
            buffer.properties = entry.properties
            signal.emit 'file-opened', :file, :buffer

          log.error "Failed to load #{file}: #{err}" unless status

        if session.recently_closed
          @_recently_closed = [{file: File(file_info.file), last_shown: file_info.last_shown} for file_info in *session.recently_closed]

      if session.window
        with session.window
          window.maximized = .maximized
          window.fullscreen = .fullscreen

  _set_initial_status: (window) =>
    if log.last_error
      startup_errors = [e for e in *log.entries when e.level == 'error']
      window.status\error "#{log.last_error.message} (#{#startup_errors} startup errors in total)"
    else
      window.status\info 'Howl ready.'

  _load_base: =>
    require 'howl.variables.core_variables'
    require 'howl.modes'

  _load_core: =>
    require 'howl.completion.in_buffer_completer'
    require 'howl.completion.api_completer'
    require 'howl.interactions.basic'
    require 'howl.interactions.buffer_selection'
    require 'howl.interactions.bundle_selection'
    require 'howl.interactions.clipboard'
    require 'howl.interactions.external_command'
    require 'howl.interactions.file_selection'
    require 'howl.interactions.line_selection'
    require 'howl.interactions.location_selection'
    require 'howl.interactions.mode_selection'
    require 'howl.interactions.replacement'
    require 'howl.interactions.search'
    require 'howl.interactions.select'
    require 'howl.interactions.signal_selection'
    require 'howl.interactions.text_entry'
    require 'howl.interactions.variable_assignment'
    require 'howl.commands.file_commands'
    require 'howl.commands.app_commands'
    require 'howl.commands.ui_commands'
    require 'howl.commands.edit_commands'
    require 'howl.editing'
    require 'howl.ui.icons.font_awesome'
    require 'howl.janitor'
    require 'howl.inspect'
    require 'howl.file_search'

  _load_application_icon: =>
    dir = @root_dir
    while dir
      icon = dir\join('share/icons/hicolor/scalable/apps/howl.svg')
      if icon.exists
        status, err = pcall Gtk.Window.set_default_icon_from_file, icon.path
        log.error "Failed to load application icon: #{err}" unless status
        return

      dir = dir.parent

    log.warn "Failed to find application icon"

  _add_recently_closed: (buffer) =>
    @_recently_closed = [file_info for file_info in *@_recently_closed when file_info.file != buffer.file]
    append @_recently_closed, {
      file: buffer.file
      last_shown: buffer.last_shown
    }
    count = #@_recently_closed
    limit = config.recently_closed_limit
    if count > limit
      overage = count - limit
      @_recently_closed = [@_recently_closed[idx] for idx = 1 + overage, limit + overage]

config.define
  name: 'recently_closed_limit'
  description: 'The number of files to remember in the recently closed list'
  default: 1000
  type_of: 'number'
  scope: 'global'

config.define
  name: 'autoclose_single_buffer'
  description: 'When only one, empty buffer is open, automatically close it when another is created'
  default: true
  type_of: 'boolean'
  scope: 'global'

signal.register 'file-opened',
  description: 'Signaled right after a file was opened in a buffer',
  parameters:
    buffer: 'The buffer that the file was opened into'
    file: 'The file that was opened'

signal.register 'buffer-closed',
  description: 'Signaled right after a buffer was closed',
  parameters:
    buffer: 'The buffer that was closed'

signal.register 'app-ready',
  description: 'Signaled right after the application has completed initialization'

return Application
