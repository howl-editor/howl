m = howl.ui.markup.howl
StyledText = howl.ui.StyledText

describe 'howl', ->

  it 'returns a StyledText instance with empty styles if no markup is present', ->
    assert.same StyledText('foo', {}), m 'foo'

  it 'returns a StyledText instance with styles for howl_markup', ->
    expected = StyledText 'foo', { 1, 'number', 4 }
    assert.same expected, m '<number>foo</number>'

  it 'allows the end tag to be simplified', ->
    expected = StyledText 'foobar', { 1, 'number', 4 }
    assert.same expected, m '<number>foo</>bar'

  it 'handles multiple howl_markups', ->
    expected = StyledText 'hi my prompt!', {
      4, 'string', 6,
      7, 'error', 13,
    }
    assert.same expected, m 'hi <string>my</string> <error>prompt</>!'

  it 'content can contain newlines', ->
    expected = StyledText 'x\nx', {
      1, 'string', 4
    }
    assert.same expected, m "<string>x\nx</string>"
