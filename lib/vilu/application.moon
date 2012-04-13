-- @author Nils Nordman <nino at nordman.org>
-- @copyright 2012
-- @license MIT (see LICENSE)

import Gtk from lgi
Scintilla = require('vilu.core.scintilla')

class Application
  new: (root_dir, args) =>
    @root_dir = root_dir
    @args = args

  run: =>
    window = Gtk.Window {
      title: 'Vilu zen',
      default_width: 800,
      default_height: 600,
      on_destroy: Gtk.main_quit
    }
    sci = Scintilla()
    window\add(sci\get_widget!)
    window\show_all!

    sci\set_property('lexer.lpeg.color.theme', 'dark')

    if #@args > 1
      f = _G.assert(_G.io.open(@args[2]))
      contents = f\read('*a')
      f\close()

      dir_f = sci\get_direct_function!
      dir_p = sci\get_direct_pointer!
      sci\private_lexer_call(Scintilla.SCI_GETDIRECTFUNCTION, dir_f)
      sci\private_lexer_call(Scintilla.SCI_SETDOCPOINTER, dir_p)
      sci\private_lexer_call(Scintilla.SCI_SETLEXERLANGUAGE, 'ruby')
      sci\set_text(contents)
      sci\grab_focus!

    Gtk.main!

return Application
