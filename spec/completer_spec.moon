import Completer, Buffer, completion from howl
import Editor from howl.ui

describe 'Completer', ->
  buffer = nil
  before_each ->
    buffer = Buffer {}

  describe '.complete()', ->

    it 'instantiates completers once with (buffer, line, line-up-to-word)', ->
      buffer.text = 'mr.cat'
      factory = spy.new -> nil
      append buffer.completers, factory
      completer = Completer(buffer, 6)
      completer\complete 6
      assert.spy(factory).was.called_with buffer, buffer.lines[1], u'mr.'
      completer\complete 6
      assert.spy(factory).was.called(1)

    it 'lookups completers in completion when they are specified as strings', ->
      buffer.text = 'yowser'
      factory = spy.new -> nil
      completion.register name: 'comp-name', :factory
      append buffer.completers, 'comp-name'
      completer = Completer(buffer, 3)
      assert.spy(factory).was.called

    it 'returns completions for completers in buffer and mode', ->
      mode = completers: { -> complete: -> { 'mode' } }
      buffer.mode = mode
      append buffer.completers,  -> complete: -> { 'buffer' }
      completions = Completer(buffer, 1)\complete 1
      assert.same completions, { 'buffer', 'mode' }

    it 'runs completions for mode even if buffer has no completers', ->
      mode = completers: { -> complete: -> { 'mode' } }
      buffer.mode = mode
      assert.same Completer(buffer, 1)\complete(1), { 'mode' }

    it 'calls <completer.complete()> with (completer, word-up-to-pos, position)', ->
      buffer.text = 'mr.cat'
      comp = complete: spy.new -> {}
      append buffer.completers, -> comp
      completer = Completer(buffer, 6)

      completer\complete 6
      assert.spy(comp.complete).was.called_with comp, u'ca', 6

      completer\complete 7
      assert.spy(comp.complete).was.called_with comp, u'cat', 7

  it '.start_pos holds the start position for completing', ->
    buffer.text = 'oh cruel word'
    assert.equal 4, Completer(buffer, 9).start_pos

