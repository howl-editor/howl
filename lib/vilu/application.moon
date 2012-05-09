-- @author Nils Nordman <nino at nordman.org>
-- @copyright 2012
-- @license MIT (see LICENSE)

import Gtk from lgi
import Window, TextView, theme from vilu.ui
import Buffer, mode from vilu
import File from vilu.fs

class Application

  new: (root_dir, args) =>
    @root_dir = root_dir
    @args = args
    @windows = {}
    @buffers = {}

  new_window: (properties) =>
    props =
      title: 'Vilu zen'
      default_width: 640
      default_height: 480
      on_destroy: Gtk.main_quit

    props[k] = v for k, v in pairs(properties or {})
    window = Window props
    table.insert(@windows, window)
    window

  new_buffer: (mode) =>
    buffer = Buffer mode
    table.insert(@buffers, buffer)
    buffer

  open_file: (file, view) =>
    view.buffer.text = file.contents

  run: =>
    self\_init_themes!
    vilu.bundle.init @root_dir / 'bundle'

    window = self\new_window!
    buffer = self\new_buffer mode.by_name 'Lua'
    view = TextView buffer
    window\add_view view
    window\show_all!

    if #@args > 1
      self\open_file(File(path), view) for path in *@args[2,]

    Gtk.main!

  _init_themes: =>
    themes_root = @root_dir / 'themes'
    theme.load themes_root / 'blue.moon'
    theme.current = theme.available['Blue']

return Application
