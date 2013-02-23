import Buffer from howl
import Editor from howl.ui
import auto_pair from howl.editing

describe 'auto_pair.handle(event, editor)', ->
  local buffer, editor

  event = (character) -> character: character, key_name: character, key_code: 65

  before_each ->
    buffer = Buffer!
    editor = Editor buffer
    buffer.text = ''

  context 'when the character matches a known pair from buffer.mode.auto_pairs', ->
    before_each ->
      buffer.mode.auto_pairs = {
        '(': ')'
        '[': ']'
        '"': '"'
      }

    it 'returns true', ->
      assert.is_true auto_pair.handle event('('), editor

    it 'inserts the pair in the buffer, as one undo operation', ->
      for start_c, end_c in pairs buffer.mode.auto_pairs
        auto_pair.handle event(start_c), editor
        assert.equal "#{start_c}#{end_c}", buffer.text
        buffer\undo!
        assert.equal '', buffer.text

    it 'positions the cursor within the pair', ->
      auto_pair.handle event('['), editor
      assert.equal 2, editor.cursor.pos

    it 'does not insert an auto-pair for a same character pair if the current balance is uneven', ->
      buffer.text = '"foo'
      editor.cursor.pos = 5
      assert.is_not_true auto_pair.handle event('"'), editor

  context 'overtyping companion characters', ->
    before_each ->
      buffer.mode.auto_pairs = {
        '(': ')'
        '"': '"'
      }

    it 'overtypes any companion characters if the current pair-balance is even', ->
      buffer.text = '()'
      editor.cursor.pos = 2
      assert.is_true auto_pair.handle event(')'), editor
      assert.equal '()', buffer.text
      assert.equal 3, editor.cursor.pos

    it 'overtypes any companion characters for even pair-balance when the start characters and end character is the same', ->
      buffer.text = '""'
      editor.cursor.pos = 2
      assert.is_true auto_pair.handle event('"'), editor
      assert.equal '""', buffer.text
      assert.equal 3, editor.cursor.pos

    it 'does not overtype if the current pair-balance is non-even', ->
      buffer.text = '(foo'
      editor.cursor.pos = 5
      assert.is_not_true auto_pair.handle event(')'), editor

    it 'does not overtype if the current character is different', ->
      buffer.text = '(foo)'
      editor.cursor.pos = 6
      assert.is_not_true auto_pair.handle event(')'), editor

  it 'returns non-true when the character does not match a known pair', ->
    assert.is_not_true auto_pair.handle event('x'), editor

  it 'always returns non-true if the auto_pair config variable is false', ->
    buffer.mode.auto_pairs = { ['(']: ')' }
    buffer.config.auto_pair = false
    assert.is_not_true auto_pair.handle event('('), editor
