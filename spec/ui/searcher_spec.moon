import Buffer, config from howl
import Editor, highlight from howl.ui

describe 'Searcher', ->
  buffer = nil
  editor = Editor Buffer {}
  searcher = editor.searcher
  cursor = editor.cursor

  before_each ->
    buffer = Buffer {}
    editor.buffer = buffer

  after_each -> searcher\cancel!

  describe 'forward_to(string)', ->
    it 'moves the cursor to the next occurrence of <string>', ->
      buffer.text = 'hellö\nworld!'
      cursor.pos = 1
      searcher\forward_to 'l'
      assert.equal 3, cursor.pos
      searcher\forward_to 'ld'
      assert.equal 10, cursor.pos

    it 'highlights the match with "search"', ->
      buffer.text = 'hellö\nworld!'
      cursor.pos = 1
      searcher\forward_to 'lö'
      assert.same { 'search' }, highlight.at_pos buffer, 4
      assert.same { 'search' }, highlight.at_pos buffer, 5
      assert.not_same { 'search' }, highlight.at_pos buffer, 6

    it 'skips any matches at the current position by default', ->
      buffer.text = 'no means no'
      cursor.pos = 1
      searcher\forward_to 'no'
      assert.equal 10, cursor.pos

    it 'does not skip any matches at the current position if the searcher is active', ->
      buffer.text = 'sö nö means no'
      cursor.pos = 1
      searcher\forward_to 'n'
      assert.equal 4, cursor.pos
      searcher\forward_to 'nö'
      assert.equal 4, cursor.pos

    it 'does not move the cursor when there is no match', ->
      buffer.text = 'hello!'
      cursor.pos = 1
      searcher\forward_to 'foo'
      assert.equal 1, cursor.pos

  describe 'backward_to(string)', ->
    it 'moves the cursor to the previous occurrence of <string>', ->
      buffer.text = 'hellö\nworld!'
      cursor.pos = 11
      searcher\backward_to 'l'
      assert.equal 10, cursor.pos
      searcher\backward_to 'lö'
      assert.equal 4, cursor.pos

    it 'handles search term growing from empty', ->
      buffer.text = 'aaaaaaaa'
      cursor.pos = 5
      searcher\backward_to ''
      assert.equal 5, cursor.pos
      searcher\backward_to 'a'
      assert.equal 4, cursor.pos
      searcher\backward_to 'a'
      assert.equal 4, cursor.pos

    it 'skips any matches at the current position by default', ->
      buffer.text = 'aaaaaaaa'
      cursor.pos = 5
      searcher\backward_to 'a'
      assert.equal 4, cursor.pos

    it 'finds matches that overlap with cursor', ->
      buffer.text = 'ababababa'
      cursor.pos = 4
      searcher\backward_to 'baba'
      assert.equal 2, cursor.pos


    it 'does not skip any matches at the current position if the searcher is active', ->
      buffer.text = 'abaaaaab'
      cursor.pos = 8
      searcher\backward_to 'a'
      assert.equal 7, cursor.pos
      searcher\backward_to 'ab'
      assert.equal 7, cursor.pos

    it 'does not move the cursor when there is no match', ->
      buffer.text = 'hello!'
      cursor.pos = 3
      searcher\backward_to 'f'
      assert.equal 3, cursor.pos

  it 'cancel() moves the cursor back to the original position', ->
    buffer.text = 'hello!'
    cursor.pos = 1
    searcher\forward_to 'll'
    searcher\cancel!
    assert.equal 1, cursor.pos

  it 'next() repeats the last search in the last direction', ->
    buffer.text = 'hellö wörld'
    cursor.pos = 1
    searcher\forward_to 'ö'
    searcher\commit!
    searcher\next!
    assert.equal 8, cursor.pos

  it '.active is true if the searcher is currently active', ->
    assert.is_false searcher.active
    searcher\forward_to 'o'
    assert.is_true searcher.active
    searcher\cancel!
    assert.is_false searcher.active

