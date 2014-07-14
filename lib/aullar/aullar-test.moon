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

  if key_name == 'right'
    view.cursor\forward cursor_opts
  elseif key_name == 'left'
    view.cursor\backward cursor_opts
  elseif key_name == 'up'
    view.cursor\up cursor_opts
  elseif key_name == 'down'
    view.cursor\down cursor_opts
  elseif key_name == 'page_down'
    view.cursor\page_down cursor_opts
  elseif key_name == 'page_up'
    view.cursor\page_up cursor_opts
  elseif key_name == 'backspace'
    view\delete_back!
  else
    return false

  true

new_edit = ->
  buffer = aullar.Buffer text
  view = aullar.View buffer
  view.on_key_press = on_key_press
  view\to_gobject!

add_window = (app) ->
  window = Gtk.Window()
  window\set_default_size 800, 480
  window\move 300, 100
  window.title = 'Edit redux'
  window\add new_edit!
  app\add_window window
  window\show_all!

app = Gtk.Application 'io.howl.aullar', Gtk.Application.FLAGS_NONE
app\on_activate -> add_window app
app\run {}
