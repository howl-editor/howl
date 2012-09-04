import Buffer from lunar

describe 'Buffer', ->
  buffer = (text) ->
    with Buffer {}
      .text = text

  describe 'creation', ->
    it 'Buffer(mode) raises an error if mode is not given', ->
      assert_error -> Buffer!

    context 'when sci parameter is specified', ->
      it 'attaches .sci and .doc to the Scintilla instance', ->
        sci = get_doc_pointer: -> 'docky'
        b = Buffer {}, sci
        assert_equal b.doc, 'docky'
        assert_equal b.sci, sci

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

    describe '[nr]', ->
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

    describe '[nr] = <value>', ->
      it 'replaces the specified line with the specified value', ->
        b = buffer 'hello\nworld'
        b.lines[1] = 'hola'
        assert_equal b.text, 'hola\nworld'

      it 'removes the entire line if value is nil', ->
        b = buffer 'goodbye\ncruel\nworld'
        b.lines[2] = nil
        assert_equal b.text, 'goodbye\nworld'
        b.lines[1] = nil
        assert_equal b.text, 'world'

      it 'raises an error if the line number is invalid', ->
        b = buffer 'hello!'
        assert_raises 'Invalid index', -> b.lines['foo'] = 'bar'

    it 'delete(start, end) deletes the the lines [start, end)', ->
        b = buffer 'hello\nworld\nagain!'
        b.lines\delete 1, 3
        assert_equal b.text, 'again!'

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

    it 'pos_for(nr) returns the position for the start of <line>', ->
      b = buffer 'one\ntwo\nthree'
      assert_equal b.lines\pos_for(2), 5

    it 'nr_at_pos(pos) returns the line nr at <pos>', ->
      b = buffer 'one\ntwo\nthree'
      assert_equal b.lines\nr_at_pos(1), 1
      assert_equal b.lines\nr_at_pos(3), 1
      assert_equal b.lines\nr_at_pos(4), 1
      assert_equal b.lines\nr_at_pos(5), 2
      assert_equal b.lines\nr_at_pos(9), 3

    it 'range(start, end) returns a table with lines [start, end)', ->
      b = buffer 'one\ntwo\nthree'
      assert_table_equal b.lines\range(1, 3), { 'one', 'two' }

  describe '.file = <file>', ->
    b = buffer ''

    it 'sets the title to the basename of the file', ->
      with_tmpfile (file) ->
        b.file = file
        assert_equal b.title, file.basename

    it 'sets the buffer text to the contents of the file', ->
      b.text = 'foo'
      with_tmpfile (file) ->
        file.contents = 'yes sir'
        b.file = file
        assert_equal b.text, 'yes sir'

    it 'marks the buffer as not dirty', ->
      b.dirty = true
      with_tmpfile (file) ->
        b.file = file
        assert_false b.dirty

    it 'clears the undo history', ->
      b.text = 'foo'
      with_tmpfile (file) ->
        b.file = file
        assert_false b.can_undo

  describe 'insert(text, pos)', ->
    it 'inserts text at pos', ->
      b = buffer 'heo'
      b\insert 'll', 3
      assert_equal b.text, 'hello'

    it 'returns the position right after the inserted text', ->
      b = buffer ''
      assert_equal b\insert('hej', 1), 4

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

  it '.can_undo returns true if undo is possible, and false otherwise', ->
    b = Buffer {}
    assert_false b.can_undo
    b.text = 'bar'
    assert_true b.can_undo
    b\undo!
    assert_false b.can_undo

  describe '.can_undo = <bool>', ->
    it 'setting it to false removes any undo history', ->
      b = buffer 'hello'
      assert_true b.can_undo
      b.can_undo = false
      assert_false b.can_undo
      b\undo!
      assert_equal b.text, 'hello'

    it 'setting it to true is a no-op', ->
      b = buffer 'hello'
      assert_true b.can_undo
      b.can_undo = true
      assert_true b.can_undo
      b\undo!
      b.can_undo = true
      assert_false b.can_undo

  describe 'as_one_undo(f)', ->
    it 'allows for grouping actions as one undo', ->
      b = buffer 'hello'
      b\as_one_undo ->
        b\delete 1, 1
        b\append 'foo'
      b\undo!
      assert_equal b.text, 'hello'

    context 'when f raises an error', ->
      it 'propagates the error', ->
        b = buffer 'hello'
        assert_raises 'oh my',  ->
          b\as_one_undo -> error 'oh my'

      it 'ends the undo transaction', ->
        b = buffer 'hello'
        assert_error -> b\as_one_undo ->
          b\delete 1, 1
          error 'oh noes what happened?!?'
        b\append 'foo'
        b\undo!
        assert_equal b.text, 'ello'

  it '#buffer returns the same as buffer.size', ->
    b = buffer 'hello'
    assert_equal #b, b.size

  it 'tostring(buffer) returns the buffer title', ->
    b = buffer 'hello'
    b.title = 'foo'
    assert_equal tostring(b), 'foo'

  describe '.add_sci_ref(sci)', ->
    it 'adds the specified sci to .scis', ->
      sci = {}
      b = buffer ''
      b\add_sci_ref sci
      assert_table_equal b.scis, { sci }

    it 'sets .sci to the specified sci', ->
      sci = {}
      b = buffer ''
      b\add_sci_ref sci
      assert_equal b.sci, sci

  describe '.remove_sci_ref(sci)', ->
    it 'removes the specified sci from .scis', ->
      sci = {}
      b = buffer ''
      b\add_sci_ref sci
      b\remove_sci_ref sci
      assert_table_equal b.scis, {}

    it 'sets .sci to some other sci if they were previously the same', ->
      sci = {}
      sci2 = {}
      b = buffer ''
      b\add_sci_ref sci
      b\add_sci_ref sci2
      assert_equal b.sci, sci2
      b\remove_sci_ref sci2
      assert_equal b.sci, sci
