import Buffer from vilu

describe 'Buffer', ->
  it 'raises an error if mode is not given', ->
    assert_error -> Buffer!

  it 'the .text property allows setting and retrieving the buffer text', ->
    b = Buffer {}
    assert_blank b.text
    b.text = 'Ipsum'
    assert_equal b.text, 'Ipsum'

  it 'the .size property returns the size of the buffer text, in bytes', ->
    b = Buffer {}
    b.text = 'hello'
    assert_equal b.size, 5

  it 'delete deletes the specified number of characters', ->
    b = Buffer {}
    b.text = 'hello'
    b\delete 2, 2
    assert_equal b.text, 'hlo'

  it 'undo undoes the last operation', ->
    b = Buffer {}
    b.text = 'hello'
    b\delete 1, 1
    b\undo!
    assert_equal b.text, 'hello'


