import Buffer, config from lunar

describe 'BufferLines', ->
  buffer = (text) ->
    with Buffer {}
      .text = text

  it '# operator returns number of lines in the buffer', ->
    b = buffer 'hello\n  world\nagain!'
    assert_equal #b.lines, 3

  describe 'Line objects', ->
    buf = nil
    lines = nil

    before ->
      buf = buffer 'hello\n  world\nagain!'
      lines = buf.lines

    it '.nr holds the line number', ->
      assert_equal lines[1].nr, 1

    it '.text returns the text of the specified line, sans linebreak', ->
      assert_equal lines[1].text, 'hello'
      assert_equal lines[2].text, '  world'
      assert_equal lines[3].text, 'again!'

    it 'tostring(line) gives the same as .text', ->
      assert_equal tostring(lines[1]), lines[1].text

    describe '.text = <content>', ->
      it 'replaces the line text with <content>', ->
        lines[1].text = 'Hola'
        assert_equal buf.text, 'Hola\n  world\nagain!'

      it 'raises an error if <content> is nil', ->
        assert_raises 'nil', -> lines[1].text = nil

    it '.indentation returns the indentation for the line', ->
      assert_equal lines[1].indentation, 0
      assert_equal lines[2].indentation, 2

    it '.indentation = <nr> set the indentation for the line to <nr>', ->
      lines[3].indentation = 4
      assert_equal buf.text, 'hello\n  world\n    again!'

    it '.start_pos returns the start position for line', ->
      assert_equal lines[2].start_pos, 7

    it '.end_pos returns the end position for line', ->
      assert_equal lines[1].end_pos, 6

    it '.previous return the line above this one, or nil if none', ->
      assert_equal lines[2].previous, lines[1]
      assert_nil lines[1].previous

    it '.next return the line below this one, or nil if none', ->
      assert_equal lines[1].next, lines[2]
      assert_nil lines[3].next

    it '.indent() indents the line by <config.indent>', ->
      config.indent = 2
      buf.lines[1]\indent!
      assert_equal buf.text, '  hello\n  world\nagain!'

      config.set_local 'indent', 1, buf
      buf.lines[3]\indent!
      assert_equal buf.text, '  hello\n  world\n again!'

    it '.unindent() unindents the line by <config.indent>', ->
      buf.text = '  first\n  second'
      config.indent = 2
      buf.lines[1]\unindent!
      assert_equal buf.text, 'first\n  second'

      config.set_local 'indent', 1, buf
      buf.lines[2]\unindent!
      assert_equal buf.text, 'first\n second'

    it '#line returns the length of the line', ->
      assert_equal #lines[1], 5

    it 'lines are equal if they have the same text', ->
      lines[2] = 'hello'
      assert_equal lines[1], lines[2]

    it 'string methods can be accessed directly on the object', ->
      line = lines[3]
      assert_equal line\sub(1,2), 'ag'
      assert_equal line\find('in'), 4

  describe '[nr]', ->
    it 'returns a line object for the specified line', ->
      lines = buffer('hello\n  world\nagain!').lines
      assert_equal lines[1].text, 'hello'

    it 'returns nil if the line number is invalid', ->
      lines = buffer('hello!').lines
      assert_nil lines[2]
      assert_nil lines[0]

  describe '[nr] = <value>', ->
    it 'replaces the text of the specified line with <value>', ->
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

  it 'delete(start, end) deletes the the lines [start, end]', ->
      b = buffer 'hello\nworld\nagain!'
      b.lines\delete 1, 2
      assert_equal b.text, 'again!'

  it 'at_pos(pos) returns the line at <pos>', ->
    lines = buffer('one\ntwo\nthree').lines
    line = lines\at_pos 6
    assert_equal line.text, 'two'

  it 'range(start, end) returns a table with lines [start, end]', ->
    lines = buffer('one\ntwo\nthree').lines
    range = lines\range(1, 2)
    assert_equal #range, 2
    assert_equal range[1], lines[1]
    assert_equal range[2], lines[2]

  describe 'append(text)', ->
    it 'append(text) appends <text> with the necessary newlines', ->
      b = buffer 'one\ntwo'
      b.lines\append 'three'
      assert_equal b.text, 'one\ntwo\nthree\n'

      b = buffer 'one\ntwo\n'
      b.lines\append 'three'
      assert_equal b.text, 'one\ntwo\nthree\n'

    it 'returns a line object for the newly appended line', ->
      b = buffer 'line'
      line = b.lines\append 'omega'
      assert_equal line, b.lines[2]

  describe 'insert(line_nr, text)', ->
    it 'inserts a new line at <nr> with <text>', ->
      b = buffer 'one\ntwo'
      b.lines\insert 1, 'half'
      assert_equal b.text, 'half\none\ntwo'

      b.lines\insert 3, '1.5'
      assert_equal b.text, 'half\none\n1.5\ntwo'

    it 'raises an error if <line_nr> is invalid', ->
      b = buffer 'first\nsecond'
      assert_raises 'Invalid', -> b.lines\insert 0, 'foo'
      assert_raises 'Invalid', -> b.lines\insert 3, 'foo'

    it 'returns a line object for the newly inserted line', ->
      b = buffer 'line'
      line = b.lines\insert 1, 'alpha'
      assert_equal line, b.lines[1]

  it 'supports iterating using ipairs', ->
    b = buffer 'one\ntwo\nthree'
    for i, line in ipairs b.lines
      assert_equal line, b.lines[i]

  it 'supports iterating using pairs', ->
    b = buffer 'one\ntwo\nthree'
    for i, line in pairs b.lines
      assert_equal line, b.lines[i]
