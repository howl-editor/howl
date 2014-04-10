import inputs, config, Buffer from howl
import Editor from howl.ui
append = table.insert

require 'howl.inputs.line_input'

describe 'LineInput', ->

  it 'registers a "line" input', ->
    assert.not_nil inputs.line

  describe 'an instance of', ->
    local buffer, input

    before_each ->
      buffer = Buffer!
      buffer.text = 'one\ntwo'
      editor = Editor buffer
      input = inputs.line 'line', editor

    it '.should_complete() returns true', ->
      assert.is_true input\should_complete!

    describe '.complete(text)', ->
      it 'returns the nr and lines available in the buffer as completions', ->
        completions = input\complete ''
        assert.equal 2, #completions
        assert.same { '1', 'one' }, { completions[1][1], tostring completions[1][2] }

    describe '.value_for(text)', ->
      context 'with no prior readline interaction', ->
        it 'returns the specified line and the column position 1', ->
          assert.same { buffer.lines[1], 1 }, { input\value_for '1' }

      context 'with a prior submit', ->
        it 'returns the relevant line and the matching column', ->
          readline = text: 'ne'
          input\on_selection_changed { 1, buffer.lines[1] }, readline
          assert.same { buffer.lines[1], 2 }, { input\value_for '1' }
