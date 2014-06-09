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

    it 'matches at the current position', ->
      buffer.text = 'no means no'
      cursor.pos = 1
      searcher\forward_to 'no'
      assert.equal 1, cursor.pos

    it 'handles growing match from empty', ->
      buffer.text = 'no means no'
      cursor.pos = 1
      searcher\forward_to ''
      assert.equal 1, cursor.pos
      searcher\forward_to 'n'
      assert.equal 1, cursor.pos
      searcher\forward_to 'no'
      assert.equal 1, cursor.pos

    it 'does not move the cursor when there is no match', ->
      buffer.text = 'hello!'
      cursor.pos = 1
      searcher\forward_to 'foo'
      assert.equal 1, cursor.pos

    describe 'next()', ->
      it 'moves to the next match', ->
        buffer.text = 'aaaa'
        cursor.pos = 1
        searcher\forward_to 'a'
        assert.equal 1, cursor.pos
        searcher\next!
        assert.equal 2, cursor.pos
        searcher\next!
        assert.equal 3, cursor.pos

    describe 'previous()', ->
      it 'moves to the previous match', ->
        buffer.text = 'aaaa'
        cursor.pos = 4
        searcher\forward_to 'a'
        assert.equal 4, cursor.pos
        searcher\previous!
        assert.equal 3, cursor.pos
        searcher\previous!
        assert.equal 2, cursor.pos

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
      searcher\backward_to 'aa'
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

    describe 'next()', ->
      it 'moves to the next match', ->
        buffer.text = 'aaaa'
        cursor.pos = 4
        searcher\backward_to 'a'
        searcher\next!
        assert.equal 4, cursor.pos

    describe 'previous()', ->
      it 'moves to the previous match', ->
        buffer.text = 'aaaa'
        cursor.pos = 3
        searcher\backward_to 'a'
        searcher\next!
        searcher\previous!
        assert.equal 2, cursor.pos

  describe 'forward_to(string, "word")', ->
    it 'moves the cursor to the next occurrence of word match <string>', ->
      buffer.text = 'hello helloo hello'
      cursor.pos = 2
      searcher\forward_to 'hello', 'word'
      assert.equal 14, cursor.pos

    it 'matches at the current position', ->
      buffer.text = 'no means no'
      cursor.pos = 1
      searcher\forward_to 'no', 'word'
      assert.equal 1, cursor.pos

    describe 'next()', ->
      it 'moves to the next word match', ->
        buffer.text = 'hello helloo hello'
        cursor.pos = 1
        searcher\forward_to 'hello', 'word'
        searcher\next!
        assert.equal 14, cursor.pos

    describe 'previous()', ->
      it 'moves to the previous word match', ->
        buffer.text = 'hello helloo hello'
        cursor.pos = 1
        searcher\forward_to 'hello', 'word'
        searcher\next!
        searcher\previous!
        assert.equal 1, cursor.pos

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

  it 'repeat_last() repeats the last search in the last direction', ->
    buffer.text = 'hellö wörld'
    cursor.pos = 1

    searcher\forward_to 'ö'
    searcher\commit!
    assert.equal 5, cursor.pos
    searcher\repeat_last!
    assert.equal 8, cursor.pos

    cursor.pos = 11
    searcher\backward_to 'ö'
    searcher\commit!
    assert.equal 8, cursor.pos
    searcher\repeat_last!
    assert.equal 5, cursor.pos

  it '.active is true if the searcher is currently active', ->
    assert.is_false searcher.active
    searcher\forward_to 'o'
    assert.is_true searcher.active
    searcher\cancel!
    assert.is_false searcher.active
