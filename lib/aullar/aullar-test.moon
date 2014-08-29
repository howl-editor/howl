args = {...}
Gtk = require 'ljglibs.gtk'
{:parse_key_event} = require 'ljglibs.util'
callbacks = require 'ljglibs.callbacks'
aullar = require 'aullar'

gobject = require('ljglibs.gobject')
gsignal = gobject.signal

callbacks.configure on_error: error
io.stdout\setvbuf 'no'

text = [[
  Oh, let's get funky now shall we?

  Draw me, and let me edit goddamnit.
]]

if #args > 0
  text = howl.io.File(args[1]).contents

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
  else
    return false

  true

new_edit = (buffer) ->
  view = aullar.View buffer
  view.on_key_press = on_key_press
  view\to_gobject!

add_window = (app) ->
  buffer = aullar.Buffer text
  window = Gtk.Window()
  window\set_default_size 800, 480
  window\move 300, 100
  window.title = 'Edit redux'
  -- window\add new_edit buffer
  window\add Gtk.Box Gtk.ORIENTATION_HORIZONTAL, {
    { expand: true, new_edit buffer },
    { expand: true, new_edit buffer }
  }

  app\add_window window
  window\show_all!

app = Gtk.Application 'io.howl.aullar', Gtk.Application.FLAGS_NONE
app\on_activate -> add_window app
app\run {}
