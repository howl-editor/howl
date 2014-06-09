import app, inputs from howl

require 'howl.inputs.search_inputs'

describe 'search_inputs', ->

  it 'registers a "forward_search" input', ->
    assert.not_nil inputs.forward_search

  describe 'forward_search input', ->
    local searcher, input

    before_each ->
      searcher = {}
      app.editor = :searcher
      input = inputs.forward_search!

    after_each -> app.editor = nil

    it 'should_complete() returns true', ->
      assert.is_true input\should_complete!

    it 'complete(text) searches forward for <text>', ->
      searcher.forward_to = spy.new -> true
      input\complete 'foo'
      assert.spy(searcher.forward_to).was.called_with searcher, 'foo', 'plain'

    it 'on_cancelled() calls cancel() on the searcher', ->
      searcher.cancel = spy.new -> true
      input\on_cancelled!
      assert.spy(searcher.cancel).was.called_with searcher

    it 'value_for(text) returns <text>', ->
      assert.equal 'foo', input\value_for 'foo'

  describe 'replace input', ->
    local input, readline

    before_each ->
      input = inputs.replace!
      readline = prompt: 'replace ', text: ''

    describe 'on_submit', ->
      context 'when no target has been specified yet', ->
        it 'returns false', ->
          assert.is_false input\on_submit 'foo', readline

        it 'changes the prompt to show the selected target and resets the text', ->
          input\on_submit 'foo', readline
          assert.equals "replace 'foo' with ", readline.prompt
          assert.equals "", readline.text

      context 'when target has been specified already', ->
        it 'returns non-false', ->
          input\on_submit 'foo', readline
          assert.is_not_false input\on_submit 'bar', readline

        it 'returns non-false even for an empty string', ->
          input\on_submit 'foo', readline
          assert.is_not_false input\on_submit '', readline

    describe 'value_for', ->
      it 'returns a table containing target and replacement', ->
        input\on_submit 'foo', readline
        input\on_submit 'bar', readline
        assert.same { 'foo', 'bar' }, input\value_for 'bar', readline

