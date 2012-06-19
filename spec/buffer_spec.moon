import Buffer from vilu

describe 'Buffer', ->
  buffer = (text) ->
    b = Buffer {}
    b.text = text
    b

  it 'Buffer(mode) raises an error if mode is not given', ->
    assert_error -> Buffer!

  it 'the .text property allows setting and retrieving the buffer text', ->
    b = Buffer {}
    assert_blank b.text
    b.text = 'Ipsum'
    assert_equal b.text, 'Ipsum'

  it 'the .size property returns the size of the buffer text, in bytes', ->
    assert_equal buffer('hello').size, 5

  it 'the .dirty property indicates and allows setting the modified status', ->
    b = Buffer {}
    assert_false b.dirty
    b.text = 'hello'
    assert_true b.dirty
    b.dirty = false
    assert_false b.dirty
    b.dirty = true
    assert_true b.dirty
    assert_equal b.text, 'hello' -- toggling should not have changed text

  describe '.lines object', ->
    it '# operator returns number of lines in the buffer', ->
      b = buffer 'hello\n  world\nagain!'
      assert_equal #b.lines, 3

    describe '[] operator', ->
      it 'returns the text of the specified line, sans linebreak', ->
        b = buffer 'hello\n  world\nagain!'
        lines = b.lines
        assert_equal lines[1], 'hello'
        assert_equal lines[2], '  world'
        assert_equal lines[3], 'again!'

      it 'returns nil if the line number is invalid', ->
        b = buffer 'hello!'
        assert_nil b.lines[2]
        assert_nil b.lines[0]

      it 'supports iterating using ipairs', ->
        b = buffer 'one\ntwo\nthree'
        collected = {}
        for i, line in ipairs b.lines
          collected[#collected + 1] = line
        assert_table_equal collected, { 'one', 'two', 'three' }

      it 'supports iterating using pairs', ->
        b = buffer 'one\ntwo\nthree'
        collected = {}
        for i, line in pairs b.lines
          collected[#collected + 1] = line
        assert_table_equal collected, { 'one', 'two', 'three' }

  it 'clear_undo_history clears all undo history', ->
    b = buffer 'hello'
    b\clear_undo_history!
    b\undo!
    assert_equal b.text, 'hello'

  it 'insert(text, pos) inserts text at pos', ->
    b = buffer 'heo'
    b\insert 'll', 3
    assert_equal b.text, 'hello'

  it 'append(text) appends the specified text', ->
    b = buffer 'hello'
    b\append ' world'
    assert_equal b.text, 'hello world'

  it 'delete deletes the specified number of characters', ->
    b = buffer 'hello'
    b\delete 2, 2
    assert_equal b.text, 'hlo'

  it 'undo undoes the last operation', ->
    b = buffer 'hello'
    b\delete 1, 1
    b\undo!
    assert_equal b.text, 'hello'
