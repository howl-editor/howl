state = bundle_load 'state.moon'
import move from state

map = {}
setfenv 1, map

export *

j = (editor) -> move editor, -> editor.cursor\down!
k = (editor) -> move editor, -> editor.cursor\up!
h = (editor) -> move editor, -> editor.cursor\left!
l = (editor) -> move editor, -> editor.cursor\right!
e = (editor) -> move editor, -> editor.cursor\word_right_end!
w = (editor) -> move editor, -> editor.cursor\word_right!
b = (editor) -> move editor, -> editor.cursor\word_left!
G = (editor) -> move editor, -> editor.cursor\eof!
map['0'] = (editor) -> move editor, -> editor.cursor\home!
map['$'] = (editor) -> move editor, -> editor.cursor\line_end!

on_unhandled = (translations) -> return ->
  state.reset!
  true

return map
