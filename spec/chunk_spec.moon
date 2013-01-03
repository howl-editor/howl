import Chunk, Buffer from howl

describe 'Chunk', ->

  buffer = Buffer {}

  before_each ->
    buffer.text = 'Liñe 1 öf text'

  it '.start_pos returns the start_pos passed in constructor', ->
    assert.equal 3, Chunk(buffer, 3, 7).start_pos

  it '.end_pos returns the end_pos passed in constructor', ->
    assert.equal 7, Chunk(buffer, 3, 7).end_pos

  it '.text returns the text in the range [start_pos..end_pos]', ->
    assert.equal 'ñe 1', Chunk(buffer, 3, 6).text

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

  it 'delete() deletes the chunk', ->
    Chunk(buffer, 1, 5)\delete!
    assert.equal '1 öf text', buffer.text

  it 'tostring(chunk) returns .text', ->
    chunk = Chunk(buffer, 3, 6)
    assert.equal chunk.text, tostring(chunk)

  it '#chunk returns the size of the chunk', ->
    chunk = Chunk(buffer, 3, 6)
    assert.equal 4, #chunk
