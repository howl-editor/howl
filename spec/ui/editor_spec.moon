import Buffer from vilu
import Window, Editor from vilu.ui

describe 'Editor', ->
  buffer = Buffer {}
  editor = Editor buffer

  it 'new_line adds a newline at the current position', ->
    buffer.text = 'hello'
    editor.cursor.pos = 2
    editor\new_line!
    assert_equal buffer.text, 'h\nello'

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
