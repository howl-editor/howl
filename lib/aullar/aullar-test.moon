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

  if key_name == 'right'
    view\move_cursor view.cursor + 1
  elseif key_name == 'left'
    view\move_cursor math.max(view.cursor - 1, 0)
  elseif key_name == 'backspace'
    view\delete_back!
   else
    return false

  true

new_edit = ->
  buffer = aullar.Buffer text
  view = aullar.View!
  view\set_buffer buffer
  view.on_key_press = on_key_press
  view\to_gobject!

add_window = (app) ->
  window = Gtk.Window()
  window\set_default_size 800, 600
  window.title = 'Edit redux'
  window\add new_edit!
  app\add_window window
  window\show_all!

app = Gtk.Application 'io.howl.aullar', Gtk.Application.FLAGS_NONE
app\on_activate -> add_window app
app\run {}
