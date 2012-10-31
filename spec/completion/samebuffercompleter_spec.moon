import Buffer from lunar
import completion from lunar

require 'lunar.completion.samebuffercompleter'

describe 'SameBufferCompleter.complete()', ->
  buffer = nil
  factory = completion.same_buffer.factory
  before_each -> buffer = Buffer {}

  it 'returns completions for local matches in the buffer', ->
    buffer.text = [[
Hello there
  some symbol (foo) {
    if yikes {
      say_it = 'blarg'
      s
    }
  }

  other sion (arg) {
    saphire = 'this too'
  }
]]
    line = buffer.lines[5]
    completer = factory(buffer, line, '       ')
    comps = completer\complete 's', line.end_pos
    table.sort comps
    assert.same { 'saphire', 'say_it', 'sion', 'some', 'symbol' }, comps

  it 'does not include the token being completed itself', ->
    buffer.text = [[
text
te
]]
    line = buffer.lines[2]
    completer = factory(buffer, line, '')
    comps = completer\complete 'te', line.end_pos
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
    completer = factory(buffer, line, '')
    comps = completer\complete 'tw', line.end_pos
    assert.same { 'twitter', 'two', 'twice' }, comps
