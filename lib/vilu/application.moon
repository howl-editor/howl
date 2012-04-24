-- @author Nils Nordman <nino at nordman.org>
-- @copyright 2012
-- @license MIT (see LICENSE)

import Gtk from lgi
import GtkSource from lgi
import Window, TextView from vilu.ui
import Buffer from vilu
import File from vilu.fs

class Application

  new: (root_dir, args) =>
    @root_dir = root_dir
    @args = args
    @windows = {}
    @buffers = {}

    @style_mgr = GtkSource.StyleSchemeManager.get_default!
    @style_scheme = @style_mgr\get_scheme 'cobalt'
    @lang_mgr = GtkSource.LanguageManager.get_default!

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
    buffer = Buffer @style_scheme
    table.insert(@buffers, buffer)
    buffer

  open_file: (file, view) =>
    buffer = view.buffer
    sb = buffer.sbuf
    sb.text = file.contents
    iter = sb\get_iter_at_line 0
    sb\place_cursor iter
    lang = @lang_mgr\guess_language file\tostring!
    sb.language = @lang_mgr\get_language('lua')
    sb.language = lang
    sb.style_scheme = @style_scheme

  run: =>
--     Gtk.init @args
    buffer = self\new_buffer!
    view = TextView buffer
    window = self\new_window!
    window\add_view view
    window\show_all!

    if #@args > 1
      self\open_file(File(path), view) for path in *@args[2,]

    Gtk.main!

return Application
