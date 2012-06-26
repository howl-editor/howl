import Gtk from lgi

import Buffer from vilu
import Window, Editor from vilu.ui

describe 'Editor', ->
  buffer = Buffer {}
  editor = Editor buffer
  window = Gtk.OffscreenWindow!
  window\add editor\to_gobject!
  window\show_all!

  it 'new_line adds a newline at the current position', ->
    buffer.text = 'hello'
    editor.cursor.pos = 2
    editor\new_line!
    assert_equal buffer.text, 'h\nello'

  it 'insert(text) inserts the text at the cursor, and moves cursor after text', ->
    buffer.text = 'hello'
    editor.cursor.pos = 6
    editor\insert ' world'
    assert_equal buffer.text, 'hello world'
    assert_equal editor.cursor.pos, 12

  it 'paste pastes the contents of the clipboard at the current position', ->
    buffer.text = 'hello'
    editor.selection\set 1, 2
    editor.selection\copy!
    editor\paste!
    assert_equal buffer.text, 'hhello'

  it 'delete_line deletes the current line', ->
    buffer.text = 'hello\nworld!'
    editor.cursor.pos = 1
    editor\delete_line!
    assert_equal buffer.text, 'world!'

  it 'join_lines joins the current line with the one after', ->
    buffer.text = 'hello\n    world!'
    editor.cursor.pos = 1
    editor\join_lines!
    assert_equal buffer.text, 'hello world!'
    assert_equal editor.cursor.pos, 6
