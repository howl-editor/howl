import Buffer, config from howl

describe 'BufferLines', ->
  buffer = (text) ->
    with Buffer {}
      .text = text

  it '# operator returns number of lines in the buffer', ->
    b = buffer 'hello\n  world\nagain!'
    assert.equal #b.lines, 3

  describe 'Line objects', ->
    buf = nil
    lines = nil

    before_each ->
      buf = buffer 'hƏllØ\n  wØrld\nagain!'
      lines = buf.lines

    it '.buffer points to the corresponding buffer', ->
      assert.same buf, lines[1].buffer

    it '.nr holds the line number', ->
      assert.equal lines[1].nr, 1

    it '.text returns the text of the specified line, sans linebreak', ->
      assert.equal lines[1].text, 'hƏllØ'
      assert.equal lines[2].text, '  wØrld'
      assert.equal lines[3].text, 'again!'

    it 'tostring(line) gives the same as .text', ->
      assert.equal tostring(lines[1]), lines[1].text

    describe '.text = <content>', ->
      it 'replaces the line text with <content>', ->
        lines[1].text = 'Hola'
        assert.equal buf.text, 'Hola\n  wØrld\nagain!'

      it 'raises an error if <content> is nil', ->
        assert.raises 'nil', -> lines[1].text = nil

    it '.indentation returns the indentation for the line', ->
      assert.equal lines[1].indentation, 0
      assert.equal lines[2].indentation, 2

    it '.indentation = <nr> set the indentation for the line to <nr>', ->
      lines[3].indentation = 4
      assert.equal 'hƏllØ\n  wØrld\n    again!', buf.text

    it '.start_pos returns the start position for line', ->
      assert.equal lines[2].start_pos, 7
      buf.text = ''
      assert.equal lines[1].start_pos, 1

    it '.end_pos returns the end position for line, right before the newline', ->
      assert.equal lines[1].end_pos, 6
      buf.text = ''
      assert.equal lines[1].end_pos, 1

    it '.previous returns the line above this one, or nil if none', ->
      assert.equal lines[2].previous, lines[1]
      assert.is_nil lines[1].previous

    it '.previous_non_blank returns the first preceding non-blank line, or nil if none', ->
      assert.is_nil lines[1].previous_non_blank
      assert.equal lines[1], lines[2].previous_non_blank
      lines\insert 3, ''
      assert.equal lines[2], lines[4].previous_non_blank

    it '.next_non_blank returns the first succeding non-blank line, or nil if none', ->
      assert.is_nil lines[3].next_non_blank
      assert.equal lines[3], lines[2].next_non_blank
      lines\insert 3, ''
      assert.equal lines[4], lines[2].next_non_blank

    it '.next returns the line below this one, or nil if none', ->
      assert.equal lines[1].next, lines[2]
      assert.is_nil lines[3].next

    it '.chunk is a Chunk object for the line, disregarding the newline', ->
      line = lines[1]
      chunk = line.chunk
      assert.equal 'Chunk', typeof chunk
      assert.equal line.text, chunk.text
      assert.equal line.start_pos, chunk.start_pos
      assert.equal line.end_pos - #buf.eol, chunk.end_pos

    it '.indent() indents the line by <config.indent>', ->
      config.indent = 2
      buf.lines[1]\indent!
      assert.equal '  hƏllØ\n  wØrld\nagain!', buf.text

      buf.config.indent = 1
      buf.lines[3]\indent!
      assert.equal '  hƏllØ\n  wØrld\n again!', buf.text

    it '.unindent() unindents the line by <config.indent>', ->
      buf.text = '  first\n  second'
      config.indent = 2
      buf.lines[1]\unindent!
      assert.equal buf.text, 'first\n  second'

      buf.config.indent = 1
      buf.lines[2]\unindent!
      assert.equal buf.text, 'first\n second'

    it '#line returns the length of the line', ->
      assert.equal #lines[1], 5

    it 'lines are equal if they have the same text', ->
      lines[2] = 'hƏllØ'
      assert.equal lines[1], lines[2]

    it 'string methods can be accessed directly on the object', ->
      buf.text = 'first line'
      line = lines[1]
      assert.equal 'fi', line\sub(1,2)
      assert.equal 8, (line\find('in'))
      assert.equal 'first win', (line\gsub('line', 'win'))

    it 'string properties can be accessed directly on the object', ->
      assert.is_false lines[1].empty
      assert.is_false lines[1].blank
      lines[1] = ''
      assert.is_true lines[1].empty
      assert.is_true lines[1].blank

  describe '[nr]', ->
    it 'returns a line object for the specified line', ->
      lines = buffer('hello\n  world\nagain!').lines
      assert.equal lines[1].text, 'hello'

    it 'returns nil if the line number is invalid', ->
      lines = buffer('hello!').lines
      assert.is_nil lines[2]
      assert.is_nil lines[0]

  describe '[nr] = <value>', ->
    it 'replaces the text of the specified line with <value>', ->
      b = buffer 'hellØ\nwØrld'
      b.lines[1] = 'hØla'
      assert.equal b.text, 'hØla\nwØrld'

    it 'removes the entire line if value is nil', ->
      b = buffer 'gØØdbye\ncruel\nwØrld'
      b.lines[2] = nil
      assert.equal 'gØØdbye\nwØrld', b.text
      b.lines[1] = nil
      assert.equal 'wØrld' ,b.text

    it 'raises an error if the line number is invalid', ->
      b = buffer 'hello!'
      assert.raises 'Invalid index', -> b.lines['foo'] = 'bar'

  it 'delete(start, end) deletes the the lines [start, end]', ->
      b = buffer 'hellØ\nwØrld\nagain!'
      b.lines\delete 1, 2
      assert.equal b.text, 'again!'

  it 'at_pos(pos) returns the line at <pos>', ->
    lines = buffer('Øne\ntwØ\nthree').lines
    line = lines\at_pos 5
    assert.equal 'twØ', line.text

  describe 'range(start, end)', ->
    it 'returns a table with lines [start, end]', ->
      lines = buffer('one\ntwo\nthree').lines
      range = lines\range 1, 2
      assert.same { lines[1], lines[2] }, range

    it 'start can be greater than end', ->
      lines = buffer('one\ntwo\nthree').lines
      range = lines\range 2, 1
      assert.same { lines[1], lines[2] }, range

  describe 'for_text_range(start_pos, end_pos)', ->
    it 'returns a table with lines between [start_pos, end_pos]', ->
      lines = buffer('one\ntwo\nthree').lines
      range = lines\for_text_range 2, 6
      assert.same { lines[1], lines[2] }, range

    it 'start_pos can be greater than end_pos', ->
      lines = buffer('one\ntwo\nthree').lines
      range = lines\for_text_range 6, 1
      assert.same { lines[1], lines[2] }, range

    it 'does not include lines only touched at the start or end positions', ->
      lines = buffer('one\ntwo\nthree').lines
      range = lines\for_text_range lines[1].end_pos, lines[3].start_pos
      assert.same { lines[2] }, range

  describe 'append(text)', ->
    it 'append(text) appends <text> with the necessary newlines', ->
      b = buffer 'one\ntwo'
      b.lines\append 'three'
      assert.equal b.text, 'one\ntwo\nthree\n'

      b = buffer 'one\ntwo\n'
      b.lines\append 'three'
      assert.equal b.text, 'one\ntwo\nthree\n'

    it 'returns a line object for the newly appended line', ->
      b = buffer 'line'
      line = b.lines\append 'omega'
      assert.equal line, b.lines[2]

  describe 'insert(line_nr, text)', ->
    it 'inserts a new line at <nr> with <text>', ->
      b = buffer 'one\ntwo'
      b.lines\insert 1, 'half'
      assert.equal b.text, 'half\none\ntwo'

      b.lines\insert 3, '1.5'
      assert.equal b.text, 'half\none\n1.5\ntwo'

    it 'raises an error if <line_nr> is invalid', ->
      b = buffer 'first\nsecond'
      assert.raises 'Invalid', -> b.lines\insert 0, 'foo'
      assert.raises 'Invalid', -> b.lines\insert 3, 'foo'

    it 'returns a line object for the newly inserted line', ->
      b = buffer 'line'
      line = b.lines\insert 1, 'alpha'
      assert.equal line, b.lines[1]

  it 'supports iterating using ipairs', ->
    b = buffer 'one\ntwo\nthree'
    for i, line in ipairs b.lines
      assert.equal line, b.lines[i]

  it 'supports iterating using pairs', ->
    b = buffer 'one\ntwo\nthree'
    for i, line in pairs b.lines
      assert.equal line, b.lines[i]
