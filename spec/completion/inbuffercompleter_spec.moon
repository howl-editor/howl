import Buffer from howl
import completion from howl

require 'howl.completion.inbuffercompleter'
require 'howl.variables.core_variables'

describe 'InBufferCompleter.complete()', ->
  local buffer, lines
  factory = completion.in_buffer.factory

  before_each ->
    buffer = Buffer {}
    lines = buffer.lines

  complete_at = (pos) ->
    context = buffer\context_at pos
    completer = factory buffer, context
    completer\complete context

  it 'returns strict and fuzzy completions for local matches in the buffer', ->
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
ter
]]
    assert.same { 'text' }, complete_at lines[2].end_pos - 1

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