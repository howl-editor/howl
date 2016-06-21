import ActionBuffer, style, StyledText from howl.ui

describe 'ActionBuffer', ->
  buf = ActionBuffer!

  before_each -> buf.text = ''

  it 'behaves like a Buffer', ->
    buf.text = 'hello'
    assert.equal buf.text, 'hello'
    buf\append ' world'
    assert.equal buf.text, 'hello world'

  it 'does not collection undo revisions by default', ->
    assert.is_false ActionBuffer().collect_revisions

  describe '.insert(object, pos[ , style])', ->

    context 'with no specified style', ->

      it 'inserts the object with no specific style and returns the next position', ->
        assert.equal 6, buf\insert 'hello', 1
        assert.equal 'hello', buf.text
        assert.is_nil style.at_pos(buf, 1)

      it 'returns <pos> and leaves the buffer untouched for an empty string', ->
        assert.equal 1, buf\insert('', 1)
        assert.equal '', buf.text

    context 'with style specified', ->

      it 'styles the object with the specified style', ->
        buf.text = '˫˫'
        assert.equal 7, buf\insert('hƏllo', 2, 'keyword')
        assert.is_nil (style.at_pos(buf, 1))
        assert.equal 'keyword', (style.at_pos(buf, 2))
        assert.equal 'keyword', (style.at_pos(buf, 6))
        assert.is_nil (style.at_pos(buf, 7))

      it 'returns <pos> and leaves the buffer untouched for an empty string', ->
        assert.equal 1, buf\insert('', 1, 'keyword')
        assert.equal '', buf.text

    context 'when object is a styled object (.styles is present)', ->
      it 'inserts the corresponding .text and returns the next position', ->
        assert.equal 4, buf\insert('foo', 1)
        chunk = buf\chunk(1, 3)
        assert.equal 7, buf\insert chunk, 4
        assert.equal 'foofoo', buf.text

      it 'styles the inserted .text using .styles for the styling', ->
        buf\insert {text: 'styled', styles: { 2, 'keyword', 3, 3, 'number', 6 }}, 1
        assert.is_nil (style.at_pos(buf, 1))
        assert.equal 'keyword', (style.at_pos(buf, 2))
        assert.equal 'number', (style.at_pos(buf, 3))
        assert.equal 'number', (style.at_pos(buf, 5))
        assert.is_nil (style.at_pos(buf, 6))
        assert.equal 'styled', buf.text

      it 'still returns the next position', ->
        assert.equal 3, buf\insert StyledText('åö', {}), 1

      it 'ignores any given <style> parameter', ->
        buf\insert StyledText('foo', { 1, 'number', 4 }), 1, 'keyword'
        assert.equal 'number', (style.at_pos(buf, 1))

  describe '.append(text, style)', ->

    context 'with no specified style', ->

      it 'appends the text with no specific style and returns the next position', ->
        buf.text = 'hello'
        assert.equal #'hello world' + 1, buf\append ' world'
        assert.is_nil (style.at_pos(buf, 7))

    context 'with style specified', ->

      it 'styles the text with the specified style', ->
        buf.text = '˫'
        buf\append 'hƏllo', 'keyword'
        assert.is_nil (style.at_pos(buf, 1))
        assert.equal 'keyword', (style.at_pos(buf, 2))
        assert.equal 'keyword', (style.at_pos(buf, 6))

    context 'when object is a styled object', ->
      it 'appends the corresponding text and returns the next position', ->
        buf\insert 'foo', 1
        chunk = buf\chunk(1, 3)
        assert.equals 7, buf\append chunk
        assert.equal 'foofoo', buf.text

      it 'styles the inserted text using .styles for the styling', ->
        buf.text = 'foo'
        object = StyledText('bar', {1, 'number', 2, 2, 'keyword', 3})
        buf\insert object, 4
        assert.equal 'foobar', buf.text
        assert.equal 'number', (style.at_pos(buf, 4))
        assert.equal 'keyword', (style.at_pos(buf, 5))
        assert.is_nil (style.at_pos(buf, 6))

      it 'still returns the next position', ->
        assert.equal 3, buf\append StyledText('åö', {})

      it 'ignores any given <style> parameter', ->
        buf\append StyledText('foo', { 1, 'number', 4 }), 'keyword'
        assert.equal 'number', (style.at_pos(buf, 1))

  describe 'style(start_pos, end_pos, style)', ->
    it 'applies <style> for the inclusive text range given', ->
      buf.text = 'hƏlɩo'
      buf\style 2, 4, 'keyword'
      assert.is_nil (style.at_pos(buf, 1))
      assert.equal 'keyword', (style.at_pos(buf, 2))
      assert.equal 'keyword', (style.at_pos(buf, 4))
      assert.is_nil (style.at_pos(buf, 5))

  context 'resource management', ->
    it 'buffers are collected properly', ->
      b = ActionBuffer!
      buffers = setmetatable { b }, __mode: 'v'
      b = nil
      collectgarbage!
      assert.is_nil buffers[1]

    it 'memory usage is stable', ->
      assert_memory_stays_within '20Kb', 50, ->
        b = ActionBuffer!
        b.text = 'collect me!'

