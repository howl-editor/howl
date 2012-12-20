import inputs from howl

require 'howl.inputs.search_inputs'

describe 'search_inputs', ->

  it 'registers a "forward_search" input', ->
    assert.not_nil inputs.forward_search

  describe 'forward_search input', ->
    local searcher, input

    before_each ->
      searcher = {}
      _G.editor = :searcher
      input = inputs.forward_search!

    after_each -> _G.editor = nil

    it 'should_complete() returns true', ->
      assert.is_true input\should_complete!

    it 'complete(text) searches forward for <text>', ->
      searcher.forward_to = spy.new!
      input\complete 'foo'
      assert.spy(searcher.forward_to).was.called_with searcher, 'foo'

    it 'on_cancelled() calls cancel() on the searcher', ->
      searcher.cancel = spy.new!
      input\on_cancelled!
      assert.spy(searcher.cancel).was.called_with searcher

    it 'value_for(text) returns <text>', ->
      assert.equal 'foo', input\value_for 'foo'
