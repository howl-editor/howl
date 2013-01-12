import Buffer from howl
import completion from howl

require 'howl.completion.inbuffercompleter'

describe 'InBufferCompleter.complete()', ->
  buffer = nil
  factory = completion.in_buffer.factory
  before_each -> buffer = Buffer {}

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
    line = buffer.lines[5]
    context = buffer\context_at line.end_pos
    completer = factory buffer, context
    comps = completer\complete context
    table.sort comps
    assert.same { 'saphire', 'say_it', 'sion', 'some', 'symbol' }, comps

  it 'does not include the token being completed itself', ->
    buffer.text = [[
text
ter
]]
    line = buffer.lines[2]
    context = buffer\context_at line.end_pos - 1
    completer = factory buffer, context
    comps = completer\complete context
    assert.same { 'text' }, comps

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
    line = buffer.lines[3]
    context = buffer\context_at line.end_pos
    completer = factory buffer, context
    comps = completer\complete context
    assert.same { 'twitter', 'two', 'twice' }, comps

  it 'offers "smart" completions after the local ones', ->
    buffer.text = [[
two
twitter
fatwa
tw
the_water
]]
    line = buffer.lines[4]
    context = buffer\context_at line.end_pos
    completer = factory buffer, context
    comps = completer\complete context
    assert.same { 'twitter', 'two', 'the_water', 'fatwa' }, comps
