-- @author Nils Nordman <nino at nordman.org>
-- @copyright 2012
-- @license MIT (see LICENSE)

import Gtk from lgi
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

  new: (root_dir, args) =>
    @root_dir = root_dir
    @args = args
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
      default_width: 640
      default_height: 480
      on_destroy: (window) ->
        for k, win in ipairs @windows
          if win\to_gobject! == window
            @windows[k] = nil

        @_on_quit! if #@windows == 0

    props[k] = v for k, v in pairs(properties or {})
    window = Window props
    append @windows, window
    window

  new_editor: (buffer, window = _G.window) =>
    editor = Editor buffer
    window\add_view editor
    append @editors, editor
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
        @new_editor buffer

    if not status
      @close_buffer buffer
      log.error "Failed to open #{file}: #{err}"
      nil
    else
      buffer

  run: =>
    keyhandler.keymap = keymap
    @settings = Settings!
    @_load_variables!
    @_load_completions!
    @_load_commands!
    bundle.load_all!
    @_set_theme!
    @settings\load_user!
    window = @new_window!
    _G.window = window

    if #@args > 1
      @open_file(File(path)) for path in *@args[2,]
    else
      @_restore_session!

    if #@editors == 0 -- failed to load any files above for some reason
      @new_editor @new_buffer!

    @editors[1]\focus!
    window\show_all!
    @_set_initial_status window
    Gtk.main!

  quit: =>
    win\destroy! for win in * moon.copy @windows

  _on_quit: =>
    @_save_session!
    Gtk.main_quit!

  _save_session: =>
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

  _restore_session: =>
    session = @settings\load_system 'session'

    if session and session.version == 1
      for entry in *session.buffers
        file = File(entry.file)
        continue unless file.exists
        buffer = @new_buffer mode.for_file file
        buffer.file = file
        buffer.last_shown = entry.last_shown
        buffer.properties = entry.properties

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
    require 'howl.completion.samebuffercompleter'

  _load_commands: =>
    require 'howl.inputs.projectfile_input'
    require 'howl.inputs.file_input'
    require 'howl.inputs.buffer_input'
    require 'howl.inputs.variable_assignment_input'
    require 'howl.inputs.search_inputs'
    require 'howl.commands.file_commands'
    require 'howl.commands.app_commands'
    require 'howl.commands.ui_commands'
    require 'howl.commands.search_commands'

return Application
