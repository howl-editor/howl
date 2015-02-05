args = {...}
Gtk = require 'ljglibs.gtk'
{:parse_key_event} = require 'ljglibs.util'
callbacks = require 'ljglibs.callbacks'
aullar = require 'aullar'

gobject = require('ljglibs.gobject')
gsignal = gobject.signal
styles = require 'aullar.styles'

{:mode, :bundle} = howl
{:theme} = howl.ui

bundle.load_all!
theme_file = howl.app.root_dir / 'lib/aullar/misc/test-theme.moon'
theme.register 'aullar-test', theme_file
howl.config.theme = 'aullar-test'
theme.apply!

for name, def in pairs theme.current.styles
  styles.define name, def

callbacks.configure on_error: error
io.stdout\setvbuf 'no'

text = [[
  Oh, let's get funky now shall we?

  Draw me, and let me edit goddamnit.
]]

local buffer_mode

if #args > 0
  file = howl.io.File(args[1])
  text = file.contents
  buffer_mode = mode.for_file file

on_key_press = (view, event) ->
  key_name = event.key_name

  cursor_opts = extend: event.shift
  cursor = view.cursor

  if key_name == 'right'
    cursor\forward cursor_opts
  elseif key_name == 'left'
    cursor\backward cursor_opts
  elseif key_name == 'up'
    cursor\up cursor_opts
  elseif key_name == 'down'
    cursor\down cursor_opts
  elseif key_name == 'page_down'
    cursor\page_down cursor_opts
  elseif key_name == 'page_up'
    cursor\page_up cursor_opts
  elseif key_name == 'home'
    cursor\start_of_line cursor_opts
  elseif key_name == 'end'
    cursor\end_of_line cursor_opts
  elseif key_name == 'backspace'
    view\delete_back!
  elseif key_name == 'z' and event.control and event.shift
    view.buffer\redo!
  elseif key_name == 'z' and event.control
    view.buffer\undo!
  else
    return false

  true

new_edit = (buffer) ->
  view = aullar.View buffer
  view.listener = :on_key_press
  view\to_gobject!

add_window = (app) ->
  buffer = aullar.Buffer text
  buffer.lexer = buffer_mode and buffer_mode.lexer
  window = Gtk.Window()
  window.style_context\add_class 'main'
  window\set_default_size 800, 480
  window\move 300, 100
  window.title = 'Edit redux'
  window\add Gtk.Box Gtk.ORIENTATION_HORIZONTAL, {
    { expand: true, new_edit buffer },
    -- { expand: true, new_edit buffer }
  }

  app\add_window window
  window\show_all!

app = Gtk.Application 'io.howl.aullar', Gtk.Application.FLAGS_NONE
app\on_activate -> add_window app
app\run {}
