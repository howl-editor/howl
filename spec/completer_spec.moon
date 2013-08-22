import Completer, Buffer, completion from howl
import Editor from howl.ui

describe 'Completer', ->
  buffer = nil
  before_each ->
    buffer = Buffer {}

  describe '.complete()', ->

    it 'instantiates completers once with (buffer, context)', ->
      buffer.text = 'mr.cat'
      factory = spy.new -> nil
      append buffer.completers, factory
      completer = Completer(buffer, 6)
      completer\complete 6
      assert.spy(factory).was.called_with buffer, buffer\context_at 6
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

    it 'returns completions for mode even if buffer has no completers', ->
      mode = completers: { -> complete: -> { 'mode' } }
      buffer.mode = mode
      assert.same Completer(buffer, 1)\complete(1), { 'mode' }

    it 'returns the search string after the completions', ->
      mode = completers: { -> complete: -> { 'prefix' } }
      buffer.text = 'pre'
      buffer.mode = mode
      append buffer.completers,  -> complete: -> { 'buffer' }
      _, search = Completer(buffer, 4)\complete 4
      assert.same search, 'pre'

    it 'calls <completer.complete()> with (completer, context)', ->
      buffer.text = 'mr.cat'
      comp = complete: spy.new -> {}
      append buffer.completers, -> comp
      completer = Completer(buffer, 6)

      completer\complete 6
      assert.spy(comp.complete).was.called_with comp, buffer\context_at 6

      completer\complete 7
      assert.spy(comp.complete).was.called_with comp, buffer\context_at 7

    it 'returns completions from just one completer if completions.authoritive is set', ->
      append buffer.completers, -> complete: -> { 'one', authoritive: true }
      append buffer.completers, -> complete: -> { 'two' }
      completions = Completer(buffer, 1)\complete 1
      assert.same { 'one' }, completions

    it 'merges duplicate completions from different completers', ->
      append buffer.completers, -> complete: -> { 'yes'}
      append buffer.completers, -> complete: -> { 'yes' }
      completions = Completer(buffer, 1)\complete 1
      assert.same { 'yes' }, completions

  it '.start_pos holds the start position for completing', ->
    buffer.text = 'oh cruel word'
    assert.equal 4, Completer(buffer, 9).start_pos

  describe 'accept(completion)', ->
    context 'when hungry_completion is true', ->
      it 'replaces the current word with <completion>', ->
        buffer.text = 'hello there'
        buffer.config.hungry_completion = true
        completer = Completer(buffer, 3)
        completer\accept 'hey', 3
        assert.equal 'hey there', buffer.text

    context 'when hungry_completion is false', ->
      it 'inserts <completion> at the start position', ->
        buffer.text = 'hello there'
        buffer.config.hungry_completion = false
        completer = Completer(buffer, 7)
        completer\accept 'over', 7
        assert.equal 'hello overthere', buffer.text

    it 'returns the position after the accepted completion', ->
        buffer.text = 'hello there'
        assert.equal 5, Completer(buffer, 4)\accept 'hƏlp', 4
