-- @author Nils Nordman <nino at nordman.org>
-- @copyright 2012
-- @license MIT (see LICENSE)

import Gtk from lgi
import Window, Editor, theme from vilu.ui
import Buffer, mode, bundle, keyhandler, keymap, signal from vilu
import File from vilu.fs

class Application

  new: (root_dir, args) =>
    @root_dir = root_dir
    @args = args
    @windows = {}
    @buffers = {}

    signal.connect 'error', (e) -> print e

  new_window: (properties) =>
    props =
      title: 'Vilu zen'
      default_width: 800
      default_height: 600
      on_destroy: (window) ->
        for k, win in ipairs @windows
          if win\to_gobject! == window
            @windows[k] = nil

        Gtk.main_quit! if #@windows == 0

    props[k] = v for k, v in pairs(properties or {})
    window = Window props
    table.insert @windows, window
    window

  new_buffer: (mode) =>
    buffer = Buffer mode
    table.insert(@buffers, buffer)
    buffer

  open_file: (file, editor = _G.editor) =>
    buffer = self\new_buffer mode.for_file file
    buffer.file = file
    editor.buffer = buffer

  run: =>
    keyhandler.keymap = keymap
    @_load_variables!
    @_load_commands!
    bundle.init @root_dir / 'bundles'
    self\_set_theme!

    window = self\new_window!
    buffer = self\new_buffer mode.by_name 'Lua'
    editor = Editor buffer
    window\add_view editor

    if #@args > 1
      self\open_file(File(path), editor) for path in *@args[2,]

    window.status\info 'Vilu 0.0 ready.'
    editor\focus!
    window\show_all!
    Gtk.main!

  quit: =>
    win\destroy! for win in * moon.copy @windows

  _set_theme: =>
    theme.current = 'Tomorrow Night Blue'

  _load_variables: =>
    require 'vilu.variables.core_variables'

  _load_commands: =>
    require 'vilu.inputs.file'
    require 'vilu.commands.file_commands'
    require 'vilu.commands.app_commands'

return Application
