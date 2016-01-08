import Buffer from howl
import Editor from howl.ui
import auto_pair from howl.editing

describe 'auto_pair', ->
  describe 'handle(event, editor)', ->
    local buffer, editor, cursor

    event = (character, key_name = character) -> :character, :key_name, key_code: 65

    before_each ->
      buffer = Buffer!
      editor = Editor buffer
      cursor = editor.cursor
      buffer.text = ''

    context 'when the character matches a known pair from buffer.mode.auto_pairs', ->
      before_each ->
        buffer.mode.auto_pairs = {
          '(': ')'
          '[': ']'
          '"': '"'
        }

      context 'when there is an active selection', ->
        before_each ->
          buffer.text = ' foo '
          editor.selection\set 2, 5

        it 'surrounds the selection with the pair as one undo operation', ->
          auto_pair.handle event('('), editor
          assert.equal ' (foo) ', buffer.text
          buffer\undo!
          assert.equal ' foo ', buffer.text

        it 'returns true', ->
          assert.is_true auto_pair.handle event('('), editor

      context 'with no selection active', ->
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
          assert.equal 2, cursor.pos

        it 'does not trigger for a same character pair if the current balance is uneven', ->
          buffer.text = '"foo'
          cursor.pos = 5
          assert.is_not_true auto_pair.handle event('"'), editor

        it 'does not trigger when the next character is a word character', ->
          buffer.text = 'foo'
          cursor.pos = 1
          assert.is_not_true auto_pair.handle event('('), editor

    context 'overtyping companion characters', ->
      before_each ->
        buffer.mode.auto_pairs = {
          '(': ')'
          '"': '"'
        }

      it 'overtypes any companion characters if the current pair-balance is even', ->
        buffer.text = '()'
        cursor.pos = 2
        assert.is_true auto_pair.handle event(')'), editor
        assert.equal '()', buffer.text
        assert.equal 3, cursor.pos

      it 'overtypes any companion characters for even pair-balance when the start characters and end character is the same', ->
        buffer.text = '""'
        cursor.pos = 2
        assert.is_true auto_pair.handle event('"'), editor
        assert.equal '""', buffer.text
        assert.equal 3, cursor.pos

      it 'does not overtype if the current pair-balance is non-even', ->
        buffer.text = '(foo'
        cursor.pos = 5
        assert.is_not_true auto_pair.handle event(')'), editor

      it 'does not overtype if the current character is different', ->
        buffer.text = '(foo)'
        cursor.pos = 6
        assert.is_not_true auto_pair.handle event(')'), editor

    context 'deleting back inside a pair', ->
      before_each -> buffer.mode.auto_pairs = ['(']: ')'

      it 'returns true', ->
        buffer.text = '()'
        cursor.pos = 2
        assert.is_true auto_pair.handle event('\8', 'backspace'), editor

      it 'deletes both characters as one undo', ->
        buffer.text = '()'
        cursor.pos = 2
        auto_pair.handle event('\8', 'backspace'), editor
        assert.equal '', buffer.text
        buffer\undo!
        assert.equal '()', buffer.text

    it 'returns non-true when the character does not match a known pair', ->
      assert.is_not_true auto_pair.handle event('x'), editor

    it 'always returns non-true if the auto_pair config variable is false', ->
      buffer.mode.auto_pairs = { ['(']: ')' }
      buffer.config.auto_pair = false
      assert.is_not_true auto_pair.handle event('('), editor

    it 'takes sub modes into account', ->
      buffer.mode.auto_pairs = { ['(']: ')' }
      mode2 = auto_pairs: { ['[']: ']' }
      mode2_reg = name: 'auto_pair_test', create: -> mode2
      howl.mode.register mode2_reg

      buffer.text = '('
      buffer._buffer.styling\apply 1, {
        1, { 1, 's1', 2 }, 'auto_pair_test|s1',
      }
      assert.is_true auto_pair.handle event('['), editor

      howl.mode.unregister 'auto_pair_test'
