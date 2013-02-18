-- @author Nils Nordman <nino at nordman.org>
-- @copyright 2012
-- @license MIT (see LICENSE)

import Gtk, Gio from lgi
import Window, Editor, theme from howl.ui
import Buffer, Settings, mode, bundle, keyhandler, keymap, signal from howl
import File from howl.fs
import PropertyObject from howl.aux.moon

sort_buffers = (buffers) ->
  table.sort buffers, (a, b) ->
    return true if a.showing and not b.showing
    return false if b.showing and not a.showing
    ls_a = a.last_shown or 0
    ls_b = b.last_shown or 0
    return ls_a > ls_b if ls_a != ls_b
    a.title < b.title

class Application extends PropertyObject

  new: (@root_dir, @args) =>
    @windows = {}
    @editors = {}
    @_buffers = {}
    bundle.dirs = { @root_dir / 'bundles' }
    super!

  @property buffers: get: =>
    buffers = { table.unpack @_buffers }
    sort_buffers buffers
    buffers

  new_window: (properties) =>
    props =
      title: 'Howl'
      width: 800
      height: 640
      application: @g_app
      on_destroy: (window) ->
        for k, win in ipairs @windows
          if win\to_gobject! == window
            @windows[k] = nil

        @_on_quit! if #@windows == 0

    props[k] = v for k, v in pairs(properties or {})
    window = Window props
    append @windows, window
    _G.window = window if #@windows == 1
    window

  new_editor: (buffer, window = _G.window) =>
    editor = Editor buffer
    window\add_view editor
    append @editors, editor
    _G.editor = editor if #@editors == 1
    editor

  new_buffer: (buffer_mode) =>
    buffer_mode or= mode.by_name 'default'
    buffer = Buffer buffer_mode
    append @_buffers, buffer
    buffer

  add_buffer: (buffer, show = true) =>
    append @_buffers, buffer
    if show
      _G.editor.buffer = buffer
      _G.editor

  close_buffer: (buffer) =>
    @_buffers = [b for b in *@_buffers when b != buffer]

    if buffer.showing
      sort_buffers @_buffers
      shown_buffers = [b for b in *@_buffers when b.showing]
      hidden_buffers = [b for b in *@_buffers when not b.showing]

      if #shown_buffers == 0 and #hidden_buffers == 0
        append hidden_buffers, @new_buffer!

      for editor in *@editors
        if editor.buffer == buffer
          candidate = table.remove hidden_buffers, 1
          if candidate
            append shown_buffers, candidate
          else
            candidate = shown_buffers[1]

          editor.buffer = candidate

    buffer\destroy!

  open_file: (file, editor = _G.editor) =>
    for b in *@buffers
      if b.file == file
        editor.buffer = b
        return b

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
      buffer

  synchronize: =>
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
    @g_app = Gtk.Application.new 'io.howl.Editor', Gio.ApplicationFlags.HANDLES_OPEN
    @g_app.on_activate = -> @_load!
    @g_app.on_open = (_, files) -> @_load [File(path) for path in *files]

    -- by default we'll not open files in the same instance,
    -- but this can be toggled via the --reuse command line parameter
    args = @args
    if not @args.reuse
      @g_app\register!
      @_load [File(path) for path in *args[2,]]
      args = { args[1] }
      signal.connect 'window-focused', self\synchronize

    @g_app\run args

  quit: =>
    win\destroy! for win in * moon.copy @windows

  save_session: =>
    session = version: 1, buffers: {}

    for b in *@buffers
      continue unless b.file
      append session.buffers, {
        -- todo: don't tostring the paths once serialization is fixed
        file: tostring b.file.path
        last_shown: b.last_shown
        properties: b.properties
      }

    @settings\save_system 'session', session

  _load: (files = {}) =>
    local window
    unless @_loaded
      keyhandler.keymap = keymap
      @settings = Settings!
      @_load_variables!
      @_load_completions!
      @_load_commands!
      bundle.load_all!
      @_set_theme!
      @settings\load_user!
      theme.apply!
      @_load_application_icon!

      signal.connect 'mode-registered', self\_on_mode_registered
      signal.connect 'mode-unregistered', self\_on_mode_unregistered

      window = @new_window!
      @_set_initial_status window

    if #files > 0
      @open_file(File(path)) for path in *files
    elseif #@buffers == 0
      @_restore_session!

    if #@editors == 0 -- failed to load any files above for some reason
      @new_editor @new_buffer!

    _G.editor\focus!
    window\show_all! if window
    @_loaded = true

  _on_quit: =>
    @save_session! unless #@args > 1

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

  _restore_session: =>
    session = @settings\load_system 'session'

    if session and session.version == 1
      for entry in *session.buffers
        file = File(entry.file)
        continue unless file.exists
        status, err = pcall ->
          buffer = @new_buffer mode.for_file file
          buffer.file = file
          buffer.last_shown = entry.last_shown
          buffer.properties = entry.properties

        log.error "Failed to load #{file}: #{err}" unless status

    @new_editor @_buffers[1] or @new_buffer!

  _set_initial_status: (window) =>
    if log.last_error
      window.status\error log.last_error.message
    else
      window.status\info 'Howl 0.0 ready.'

  _set_theme: =>
    theme.current = 'Tomorrow Night Blue'

  _load_variables: =>
    require 'howl.variables.core_variables'

  _load_completions: =>
    require 'howl.completion.inbuffercompleter'

  _load_commands: =>
    require 'howl.inputs.projectfile_input'
    require 'howl.inputs.file_input'
    require 'howl.inputs.buffer_input'
    require 'howl.inputs.variable_assignment_input'
    require 'howl.inputs.search_inputs'
    require 'howl.inputs.bundle_inputs'
    require 'howl.commands.file_commands'
    require 'howl.commands.app_commands'
    require 'howl.commands.ui_commands'
    require 'howl.commands.search_commands'

  _load_application_icon: =>
    icon = tostring @root_dir\join('share/icons/hicolor/scalable/apps/howl.svg')
    icon_set, err = Gtk.Window.set_default_icon_from_file icon
    log.error "Failed to load application icon: #{err}" unless icon_set

return Application
