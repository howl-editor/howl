import Buffer, config from lunar
import Editor, highlight from lunar.ui

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
      buffer.text = 'hello\nworld!'
      cursor.pos = 1
      searcher\forward_to 'l'
      assert.equal 3, cursor.pos
      searcher\forward_to 'ld'
      assert.equal 10, cursor.pos

    it 'highlights the match with "search"', ->
      buffer.text = 'hello\nworld!'
      cursor.pos = 1
      searcher\forward_to 'll'
      assert.same { 'search' }, highlight.at_pos buffer, 3

    it 'skips any matches at the current position by default', ->
      buffer.text = 'no means no'
      cursor.pos = 1
      searcher\forward_to 'no'
      assert.equal 10, cursor.pos

    it 'does not skip any matches at the current position if the searcher is active', ->
      buffer.text = 'so no means no'
      cursor.pos = 1
      searcher\forward_to 'n'
      assert.equal 4, cursor.pos
      searcher\forward_to 'no'
      assert.equal 4, cursor.pos

    it 'does not move the cursor when there is no match', ->
      buffer.text = 'hello!'
      cursor.pos = 1
      searcher\forward_to 'foo'
      assert.equal 1, cursor.pos

  it 'cancel() moves the cursor back to the original position', ->
    buffer.text = 'hello!'
    cursor.pos = 1
    searcher\forward_to 'll'
    searcher\cancel!
    assert.equal 1, cursor.pos

  it 'next() repeats the last search in the last direction', ->
    buffer.text = 'hello world'
    cursor.pos = 1
    searcher\forward_to 'o'
    searcher\commit!
    searcher\next!
    assert.equal 8, cursor.pos

  it '.active is true if the searcher is currently active', ->
    assert.is_false searcher.active
    searcher\forward_to 'o'
    assert.is_true searcher.active
    searcher\cancel!
    assert.is_false searcher.active

