-- @author Nils Nordman <nino at nordman.org>
-- @copyright 2012
-- @license MIT (see LICENSE)

import Gtk from lgi
import Window, TextView from vilu.ui
import Buffer from vilu
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
      default_width: 800
      default_height: 600
      on_destroy: Gtk.main_quit

    props[k] = v for k, v in pairs(properties or {})
    window = Window props
    table.insert(@windows, window)
    window

  new_buffer: =>
    buffer = Buffer!
    table.insert(@buffers, buffer)
    buffer

  open_file: (file, view) =>
    buffer = view.buffer
    buffer.text = file.contents
    buffer.lexer = 'lua'

  run: =>
    window = self\new_window!
    buffer = self\new_buffer!
    view = TextView buffer
    window\add_view view
    window\show_all!

    if #@args > 1
      self\open_file(File(path), view) for path in *@args[2,]

    Gtk.main!

return Application
