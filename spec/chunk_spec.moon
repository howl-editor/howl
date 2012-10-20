import Chunk, Buffer from lunar

describe 'Chunk', ->

  buffer = Buffer {}

  before_each ->
    buffer.text = 'Line 1 of text'

  it '.start_pos returns the start_pos passed in constructor', ->
    assert.equal 3, Chunk(buffer, 3, 7).start_pos

  it '.end_pos returns the end_pos passed in constructor', ->
    assert.equal 7, Chunk(buffer, 3, 7).end_pos

  it '.text returns the text in the range [start_pos..end_pos]', ->
    assert.equal 'ne 1', Chunk(buffer, 3, 6).text

  it '.text = <string> replaces the chunk with <string>', ->
    chunk = Chunk(buffer, 3, 6)
    chunk.text = 'feguard'
    assert.equal 'Lifeguard of text', buffer.text

  it 'delete() deletes the chunk', ->
    Chunk(buffer, 1, 5)\delete!
    assert.equal '1 of text', buffer.text

  it 'tostring(chunk) returns .text', ->
    chunk = Chunk(buffer, 3, 6)
    assert.equal chunk.text, tostring(chunk)

  it '#chunk returns the size of the chunk', ->
    chunk = Chunk(buffer, 3, 6)
    assert.equal 4, #chunk
