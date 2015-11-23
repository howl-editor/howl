-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'

import Window, Editor, theme from howl.ui
import Buffer, Settings, mode, bundle, bindings, keymap, signal, interact, timer, clipboard, config from howl
import File, Process from howl.io
import PropertyObject from howl.aux.moon
Gtk = require 'ljglibs.gtk'
callbacks = require 'ljglibs.callbacks'
{:get_monotonic_time} = require 'ljglibs.glib'

append = table.insert
coro_create, coro_status = coroutine.create, coroutine.status

idle_dispatches = {
  '^signal draw$',
  '^cursor%-blink$',
  'timer'
}

is_idle_dispatch = (desc) ->
  for p in *idle_dispatches
    return true if desc\find(p) != nil
  false

last_activity = get_monotonic_time!

dispatcher = (f, description, ...)->

  unless is_idle_dispatch(description)
    last_activity = get_monotonic_time!

  co = coro_create (...) -> f ...
  status, ret = coroutine.resume co, ...

  if status
    if coro_status(co) == 'dead'
      return ret
  else
    _G.log.error "Failed to dispatch '#{description}: #{ret}'"

  false

config.define
  name: 'recently_closed_limit'
  description: 'The number of files to remember in the recently closed list'
  default: 1000
  type_of: 'number'
  scope: 'global'

sort_buffers = (buffers) ->
  table.sort buffers, (a, b) ->
    return true if a.showing and not b.showing
    return false if b.showing and not a.showing
    ls_a = a.last_shown or 0
    ls_b = b.last_shown or 0
    return ls_a > ls_b if ls_a != ls_b
    a.title < b.title

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

    super!

  @property idle: get: =>
    tonumber(get_monotonic_time! - last_activity) / 1000 / 1000

  @property buffers: get: =>
    buffers = { table.unpack @_buffers }
    sort_buffers buffers
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

    window\on_destroy (window) ->
      for k, win in ipairs @windows
        if win\to_gobject! == window
          @windows[k] = nil

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
    append @_buffers, buffer
    buffer

  add_buffer: (buffer, show = true) =>
    append @_buffers, buffer
    if show and @editor
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
      @_recently_closed = [file_info for file_info in *@_recently_closed when file_info.file != buffer.file]
      append @_recently_closed, {
        file: buffer.file
        last_shown: buffer.last_shown
      }
      count = #@_recently_closed
      limit = howl.config.recently_closed_limit
      if count > limit
        overage = count - limit
        @_recently_closed = [@_recently_closed[idx] for idx = 1 + overage, limit + overage]

    if buffer.showing
      for editor in *@editors
        if editor.buffer == buffer
          editor.buffer = @next_buffer

  open_file: (file, editor = @editor) =>
    for b in *@buffers
      if b.file == file
        editor.buffer = b
        return b, editor

    buffer = @new_buffer mode.for_file file
    status, err = pcall ->
      buffer.file = file
      if editor
        editor.buffer = buffer
      else
        editor = @new_editor buffer

    if not status
      @close_buffer buffer
      log.error "Failed to open #{file}: #{err}"
      nil
    else
      @_recently_closed = [file_info for file_info in *@_recently_closed when file_info.file != buffer.file]
      signal.emit 'file-opened', :file, :buffer
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
    @g_app = Gtk.Application app_base, Gtk.Application.HANDLES_OPEN
    @g_app\register!

    -- by default we'll not open files in the same instance,
    -- but this can be toggled via the --reuse command line parameter
    if @g_app.is_remote and not @args.reuse
      @g_app = Gtk.Application "#{app_base}-#{os.time!}", Gtk.Application.HANDLES_OPEN
      @g_app\register!

    @g_app\on_activate -> @_load!
    @g_app\on_open (_, files) -> @_load [File(path) for path in *files]

    signal.connect 'window-focused', self\synchronize
    signal.connect 'editor-destroyed', (args) ->
      @_editors =  [e for e in *@_editors when e != args.editor]

    @g_app\run args

  quit: (force = false) =>
    if force or not @_should_abort_quit!
      @save_session! unless #@args > 1

      for _, process in pairs Process.running
        process\send_signal 'KILL'

      for win in * moon.copy @windows
        win.command_line\abort_all!
        win\destroy!

      howl.clipboard.store!

  save_session: =>
    session = {
      version: 2
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

  _load: (files = {}) =>
    local window
    unless @_loaded
      @settings = Settings!
      @_load_core!
      if @settings.dir
        append bundle.dirs, @settings.dir\join 'bundles'
      bundle.load_all!
      @settings\load_user!
      theme.apply!
      @_load_application_icon!

      signal.connect 'mode-registered', self\_on_mode_registered
      signal.connect 'mode-unregistered', self\_on_mode_unregistered
      signal.connect 'buffer-saved', self\_on_buffer_saved

      window = @new_window!
      @_set_initial_status window

    for path in *files
      file = File path
      buffer = @new_buffer mode.for_file file
      buffer.file = file
      signal.emit 'file-opened', :file, :buffer

    unless @_loaded
      @_restore_session window, #files == 0

    if #@editors == 0
      @editor = @new_editor @_buffers[1] or @new_buffer!

    window\show_all! if window
    @_loaded = true
    signal.emit 'app-ready'

  _should_abort_quit: =>
    modified = [b for b in *@_buffers when b.modified]
    if #modified > 0
      if not interact.yes_or_no prompt: "Modified buffers exist, close anyway? "
        return true

    false

  _on_mode_registered: (args) =>
    -- check if any buffers with default_mode could use this new mode
    mode_name = args.name
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

  _on_buffer_saved: (args) =>
    file = args.buffer.file

    -- automatically update bytecode for howl files
    -- todo: move this away
    if file.extension and file.extension\umatch(r'(lua|moon)') and file\is_below(@root_dir)
      bc_file = File file.path\gsub "#{file.extension}$", 'bc'
      f, err = loadfile file
      if f
        bc_file.contents = string.dump f, false
      else
        bc_file\delete! if bc_file.exists
        log.error "Failed to update byte code for #{file}: #{err}"

  _restore_session: (window, restore_buffers) =>
    session = @settings\load_system 'session'

    if session and session.version >= 1
      if restore_buffers
        for entry in *session.buffers
          file = File(entry.file)
          continue unless file.exists
          status, err = pcall ->
            buffer = @new_buffer mode.for_file file
            buffer.file = file
            buffer.last_shown = entry.last_shown
            buffer.properties = entry.properties

          log.error "Failed to load #{file}: #{err}" unless status

      if session.version >= 2
        @_recently_closed = [{file: File(file_info.file), last_shown: file_info.last_shown} for file_info in *session.recently_closed]

      if session.window
        with session.window
          window.maximized = .maximized
          window.fullscreen = .fullscreen

  _set_initial_status: (window) =>
    if log.last_error
      window.status\error log.last_error.message
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
    require 'howl.interactions.selection_list'
    require 'howl.interactions.signal_selection'
    require 'howl.interactions.text_entry'
    require 'howl.interactions.variable_assignment'
    require 'howl.commands.file_commands'
    require 'howl.commands.app_commands'
    require 'howl.commands.ui_commands'
    require 'howl.commands.edit_commands'
    require 'howl.editing'
    require 'howl.ui.icons.font_awesome'

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

signal.register 'file-opened',
  description: 'Signaled right after a file was opened in a buffer',
  parameters:
    buffer: 'The buffer that the file was opened into'
    file: 'The file that was opened'

signal.register 'app-ready',
  description: 'Signaled right after the application has completed initialization'

return Application
