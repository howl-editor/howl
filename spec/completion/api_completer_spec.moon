require 'howl.completion.api_completer'
import Buffer from howl
import completion from howl
import DefaultMode from howl.modes
match = require 'luassert.match'

describe 'api_completer', ->

  factory = completion.api.factory

  describe 'complete()', ->
    api = {
      keyword: {},
      function: {},
      sub: {
        foo: {}
        bar: {}
        zed: {
          frob: {}
          other: {}
        }
      }
    }

    local buffer, mode

    complete_at = (pos) ->
      context = buffer\context_at pos
      completer = factory buffer, context
      comps = completer\complete context
      table.sort comps
      comps

    before_each ->
      mode = DefaultMode!
      mode.api = api
      mode.completers = { 'api' }
      buffer = Buffer mode

    it 'returns global completions when no prefix is found', ->
      buffer.text = ' k\nfun'
      comps = complete_at buffer.lines[1].start_pos
      assert.same { 'function', 'keyword', 'sub' }, comps
      assert.same { 'function' }, complete_at buffer.lines[2].end_pos

    it 'returns authoritive scoped completions when appropriate', ->
      buffer.text = 'sub.zed:f'
      assert.same { 'bar', 'foo', 'zed', authoritive: true }, complete_at 5
      assert.same { 'zed', authoritive: true }, complete_at 6
      assert.same { 'frob', 'other', authoritive: true }, complete_at 9

    it 'returns an empty set for non-matched prefixes', ->
      buffer.text = 'well so.sub'
      assert.same { }, complete_at 5
      assert.same { }, complete_at 8
      assert.same { }, complete_at buffer.length + 1

    context 'when mode provides a .resolve_type() method', ->
      it 'is invoked with (mode, context)', ->
        mode.resolve_type = spy.new -> nil
        buffer.text = 'lookie'
        complete_at 5
        assert.spy(mode.resolve_type).was_called_with match.is_ref(mode), buffer\context_at 5

      it 'the returned (path, part) is used for looking up completions', ->
        mode.resolve_type = -> 'sub', {'sub'}
        buffer.text = 'look.'
        assert.same { 'bar', 'foo', 'zed', authoritive: true }, complete_at 6
