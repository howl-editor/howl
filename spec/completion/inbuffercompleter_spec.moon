import Buffer, app, completion  from howl

require 'howl.completion.inbuffercompleter'
require 'howl.variables.core_variables'

describe 'InBufferCompleter.complete()', ->
  local buffer, lines
  factory = completion.in_buffer.factory

  complete_at = (pos) ->
    context = buffer\context_at pos
    completer = factory buffer, context
    completer\complete context

  before_each ->
    buffer = Buffer {}
    lines = buffer.lines

  it 'returns completions for local matches in the buffer', ->
    buffer.text = [[
Hello there
  some symbol (foo) {
    if yike {
      say_it = 'blarg'
      s
    }
  }

  other sion (arg) {
    saphire = 'that too'
  }
]]
    comps = complete_at buffer.lines[5].end_pos
    table.sort comps
    assert.same { 'saphire', 'say_it', 'sion', 'some', 'symbol' }, comps

  it 'does not include the token being completed itself', ->
    buffer.text = [[
text
te
noice
test
]]
    assert.same { 'text', 'test' }, complete_at lines[2].end_pos - 1
    assert.same { 'test' }, complete_at 3

  it 'favours matches close to the current position', ->
    buffer.text = [[
two
twitter
tw
other
and other
twice
twitter
]]
    assert.same { 'twitter', 'two', 'twice' }, complete_at lines[3].end_pos

  it 'offers "smart" completions after the local ones', ->
    buffer.text = [[
two
twitter
_fatwa
tw
the_water
]]
    assert.same { 'twitter', 'two', 'the_water', '_fatwa' }, complete_at lines[4].end_pos

  it 'works with unicode', ->
    buffer.text = [[
hellö
häst
h
]]
    assert.same { 'häst', 'hellö' }, complete_at lines[3].end_pos

  it 'detects existing words using the word_pattern variable', ->
    buffer.text = [[
*foo*/-bar
eat.food.
*
oo
]]
    buffer.config.word_pattern = '[^/%s.]+'
    assert.same { '*foo*' }, complete_at lines[3].end_pos

  context '(multiple buffers)', ->
    local buffer2, buffer3
    before_each ->
      buffer2 = Buffer buffer.mode
      buffer2.text = 'foo\n'
      app\add_buffer buffer2, false
      buffer2.last_shown = 123

      buffer3 = Buffer buffer.mode
      buffer3.text = 'fabulous\n'
      buffer3.last_shown = 12
      app\add_buffer buffer3, false

    after_each ->
      app\close_buffer buffer2, true
      app\close_buffer buffer3, true

    it 'searches up to <config.inbuffer_completion_max_buffers> other buffers', ->
      buffer.text = 'fry\nf'
      comps = complete_at buffer.lines[2].end_pos
      table.sort comps
      assert.same { 'fabulous', 'foo', 'fry' }, comps

      buffer.config.inbuffer_completion_max_buffers = 2
      comps = complete_at buffer.lines[2].end_pos
      table.sort comps
      assert.same { 'foo', 'fry' }, comps

    it 'prefers closer matches', ->
      buffer.text = 'fry\nf'
      comps = complete_at buffer.lines[2].end_pos
      assert.same { 'fry', 'foo', 'fabulous' }, comps

    it 'skips buffers with a different mode if <config.inbuffer_completion_same_mode_only> is true', ->
      buffer.config.inbuffer_completion_same_mode_only = true
      buffer2.mode = {}
      buffer.text = 'fry\nf'
      comps = complete_at buffer.lines[2].end_pos
      assert.same { 'fry', 'fabulous' }, comps

      buffer.config.inbuffer_completion_same_mode_only = false
      comps = complete_at buffer.lines[2].end_pos
      assert.same { 'fry', 'foo', 'fabulous' }, comps
