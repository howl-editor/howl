import Chunk, Buffer, styler from howl

describe 'Chunk', ->

  buffer = Buffer {}

  before_each ->
    buffer.text = 'Liñe 1 öf text'

  it '.start_pos returns the start_pos passed in constructor', ->
    assert.equal 3, Chunk(buffer, 3, 7).start_pos

  it '.end_pos returns the end_pos passed in constructor', ->
    assert.equal 7, Chunk(buffer, 3, 7).end_pos

  it '.empty is true if the chunk is empty (i.e. end_pos is lesser than start_pos)', ->
    assert.is_true Chunk(buffer, 3, 2).empty
    assert.is_true Chunk(buffer, 1, 0).empty
    assert.is_false Chunk(buffer, 1, 1).empty

  describe '.text', ->
    it 'is the text in the range [start_pos..end_pos]', ->
      assert.equal 'ñe 1', Chunk(buffer, 3, 6).text

    it 'is an empty string if the chunk is empty', ->
      assert.equal '', Chunk(buffer, 3, 2).text
      assert.equal '', Chunk(buffer, 1, 0).text

  describe '.text = <string>', ->
    it '.text = <string> replaces the chunk with <string>', ->
      chunk = Chunk(buffer, 3, 6)
      chunk.text = 'feguard'
      assert.equal 'Lifeguard öf text', buffer.text

    it 'updates .start_pos and .end_pos to reflect the new chunk', ->
      chunk = Chunk(buffer, 1, 6)
      chunk.text = 'Zen'
      assert.equal 3, chunk.end_pos
      assert.equal 'Zen', chunk.text

  describe '.styling', ->
    it 'is a table of offsets and styles, { start, "style", end [,..]}', ->
      styles = { 1, 'keyword', 3 }
      styler.apply buffer, 1, buffer.size, styles
      assert.same { 1, 'keyword', 2 }, Chunk(buffer, 2, 2).styles

    it 'is an empty table for an empty chunk', ->
      assert.same {}, Chunk(buffer, 2, 1).styles
      assert.same {}, Chunk(buffer, 1, 0).styles

  describe 'delete()', ->
    it 'deletes the chunk', ->
      Chunk(buffer, 1, 5)\delete!
      assert.equal '1 öf text', buffer.text

    it 'does nothing for an empty chunk', ->
      buffer.text = 'hello'
      Chunk(buffer, 1, 0)\delete!
      Chunk(buffer, 2, 1)\delete!
      assert.equal 'hello', buffer.text

  it 'tostring(chunk) returns .text', ->
    chunk = Chunk(buffer, 3, 6)
    assert.equal chunk.text, tostring(chunk)

  it '#chunk returns the length of the chunk', ->
    chunk = Chunk(buffer, 3, 6)
    assert.equal 4, #chunk
