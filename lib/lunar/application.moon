-- @author Nils Nordman <nino at nordman.org>
-- @copyright 2012
-- @license MIT (see LICENSE)

import Gtk from lgi
import Window, Editor, theme from lunar.ui
import Buffer, Settings, mode, bundle, keyhandler, keymap, signal from lunar
import File from lunar.fs

class Application

  new: (root_dir, args) =>
    @root_dir = root_dir
    @args = args
    @windows = {}
    @buffers = {}

    bundle.dirs = { @root_dir / 'bundles' }

  new_window: (properties) =>
    props =
      title: 'Lunar'
      default_width: 800
      default_height: 600
      on_destroy: (window) ->
        for k, win in ipairs @windows
          if win\to_gobject! == window
            @windows[k] = nil

        Gtk.main_quit! if #@windows == 0

    props[k] = v for k, v in pairs(properties or {})
    window = Window props
    append @windows, window
    window

  new_buffer: (mode) =>
    buffer = Buffer mode
    append @buffers, buffer
    buffer

  open_file: (file, editor = _G.editor) =>
    buffer = @new_buffer mode.for_file file
    buffer.file = file
    editor.buffer = buffer

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
    buffer = @new_buffer mode.by_name 'lua'
    editor = Editor buffer
    window\add_view editor

    if #@args > 1
      @open_file(File(path), editor) for path in *@args[2,]

    editor\focus!
    window\show_all!
    @_set_initial_status window
    Gtk.main!

  quit: =>
    win\destroy! for win in * moon.copy @windows

  _set_initial_status: (window) =>
    if log.last_error
      window.status\error log.last_error.message
    else
      window.status\info 'Lunar 0.0 ready.'

  _set_theme: =>
    theme.current = 'Tomorrow Night Blue'

  _load_variables: =>
    require 'lunar.variables.core_variables'

  _load_completions: =>
    require 'lunar.completion.samebuffercompleter'

  _load_commands: =>
    require 'lunar.inputs.projectfile_input'
    require 'lunar.inputs.file_input'
    require 'lunar.inputs.buffer_input'
    require 'lunar.inputs.variable_assignment_input'
    require 'lunar.commands.file_commands'
    require 'lunar.commands.app_commands'
    require 'lunar.commands.ui_commands'

return Application
