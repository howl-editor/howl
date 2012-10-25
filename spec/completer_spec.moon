import Completer, Buffer from lunar
import Editor from lunar.ui

describe 'Completer', ->
  buffer = nil
  before_each ->
    buffer = Buffer {}

  describe '.complete()', ->

    it 'returns completions for completers in buffer and mode', ->
      mode = completers: { -> { 'mode' } }
      buffer.mode = mode
      append buffer.completers,  -> { 'buffer' }
      completions = Completer(buffer, 1)\complete 1
      assert.same completions, { 'buffer', 'mode' }

    it 'runs completers for mode even if buffer has no completers', ->
      mode = completers: { -> { 'mode' } }
      buffer.mode = mode
      assert.same Completer(buffer, 1)\complete(1), { 'mode' }

    it 'calls completers with (word-up-to-pos, line-up-to-word, buffer, line)', ->
      buffer.text = 'mr.cat'
      comp = spy.new -> {}
      append buffer.completers, comp
      completer = Completer(buffer, 6)

      completer\complete 6
      assert.spy(comp).was.called_with 'ca', 'mr.', buffer, buffer.lines[1]

      completer\complete 7
      assert.spy(comp).was.called_with 'cat', 'mr.', buffer, buffer.lines[1]

  it '.start_pos holds the start position for completing', ->
    buffer.text = 'oh cruel word'
    assert.equal 4, Completer(buffer, 9).start_pos

