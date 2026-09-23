LspCompleter = require 'howl.lsp.completer'
{:Buffer} = howl

describe 'LspCompleter', ->
  local buffer, client, requests, on_update

  item = (label, extra = {}) ->
    extra.label = label
    extra

  respond = (result, err) ->
    requests[#requests].callback result, err

  completer_at = (pos) ->
    LspCompleter buffer, buffer\context_at(pos), on_update

  before_each ->
    requests = {}
    on_update = spy.new ->
    client = {
      completion_triggers: { ['.']: true }
      notify: ->
      cancel: spy.new ->
      send_request: (_, method, params, callback) ->
        table.insert requests, :method, :params, :callback
        #requests
    }
    buffer = Buffer word_pattern: r'\\w+'
    buffer.data.lsp = { :client, uri: 'file:///tmp/x.py', version: 1, dirty: false }

  it 'requests completions at the cursor, returning nothing until the response arrives', ->
    buffer.text = 'foo = ba'
    c = completer_at 9
    assert.same {}, c\complete(buffer\context_at 9)
    assert.equals 1, #requests
    assert.equals 'textDocument/completion', requests[1].method
    assert.same { line: 0, character: 8 }, requests[1].params.position
    assert.same { triggerKind: 1 }, requests[1].params.context

  it 'invokes on_update when the response arrives', ->
    buffer.text = 'ba'
    c = completer_at 3
    c\complete buffer\context_at(3)
    respond { item 'bar' }
    assert.spy(on_update).was_called(1)

  it 'returns completions from both an item list and a CompletionList', ->
    buffer.text = 'ba'
    c = completer_at 3
    c\complete buffer\context_at(3)
    respond { item('bar'), item('baz', insertText: 'baz()') }
    assert.same { {'bar', completion: 'bar', filter: 'bar', sort: 'bar'},
                  {'baz', completion: 'baz()', filter: 'baz', sort: 'baz'} }, c\complete(buffer\context_at 3)

    c = completer_at 3
    c\complete buffer\context_at(3)
    respond { isIncomplete: false, items: { item('bar', textEdit: { newText: 'bar_edit' }) } }
    comps = c\complete buffer\context_at(3)
    assert.equals 'bar_edit', comps[1].completion

  it 'orders completions by sortText, falling back to the label', ->
    buffer.text = 'b'
    c = completer_at 2
    c\complete buffer\context_at(2)
    respond { item('bz', sortText: '1'), item('ba', sortText: '2'), item('bb') }
    assert.same { 'bz', 'ba', 'bb' }, [comp[1] for comp in *c\complete(buffer\context_at 2)]

  it 'filters cached completions by the current prefix, case insensitively and without re-requesting', ->
    buffer.text = 'b'
    c = completer_at 2
    c\complete buffer\context_at(2)
    respond { item('Bar', filterText: 'bar'), item('baz'), item('bing') }
    buffer.text = 'bA'
    assert.same { 'Bar', 'baz' }, [comp[1] for comp in *c\complete(buffer\context_at 3)]
    assert.equals 1, #requests

  it 're-requests when the prefix is shorter than the requested one', ->
    buffer.text = 'ba'
    c = completer_at 3
    c\complete buffer\context_at(3)
    respond {}
    buffer.text = 'b'
    c\complete buffer\context_at(2)
    assert.equals 2, #requests

  it 're-requests for a new prefix when the result was incomplete, cancelling any pending request', ->
    buffer.text = 'b'
    c = completer_at 2
    c\complete buffer\context_at(2)
    respond { isIncomplete: true, items: { item 'bar' } }
    buffer.text = 'ba'
    c\complete buffer\context_at(3)
    assert.equals 2, #requests
    assert.same { triggerKind: 3 }, requests[2].params.context
    buffer.text = 'bar'
    c\complete buffer\context_at(4)
    assert.spy(client.cancel).was_called_with client, 2

  it 'returns nothing for a failed request', ->
    buffer.text = 'b'
    c = completer_at 2
    c\complete buffer\context_at(2)
    respond nil, 'timed out'
    assert.same {}, c\complete(buffer\context_at 2)
    assert.spy(on_update).was_called(1)
    assert.equals 1, #requests

  context 'after a trigger character', ->
    it 'sends the trigger character and returns authoritive completions', ->
      buffer.text = 'foo.'
      c = completer_at 5
      pending = c\complete buffer\context_at(5)
      assert.same { authoritive: true }, pending
      assert.same { triggerKind: 2, triggerCharacter: '.' }, requests[1].params.context
      respond { item 'bar' }
      comps = c\complete buffer\context_at(5)
      assert.is_true comps.authoritive
      assert.equals 'bar', comps[1][1]

    it 'does not return authoritive completions if the request failed', ->
      buffer.text = 'foo.'
      c = completer_at 5
      c\complete buffer\context_at(5)
      respond nil, 'error'
      assert.is_nil c\complete(buffer\context_at 5).authoritive
