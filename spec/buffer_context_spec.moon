import Buffer, BufferContext from howl
import ActionBuffer from howl.ui

require 'howl.variables.core_variables'

describe 'BufferContext', ->
  local b

  before_each ->
    b = Buffer howl.mode.by_name 'default'
    b.text = '"HƏllo", said Mr.Bačon'

  context_at = (pos) -> BufferContext b, pos

  describe '.word', ->
    it 'holds the current word', ->
      assert.equal '', context_at(1).word.text
      assert.equal 'HƏllo', context_at(2).word.text
      assert.equal 'HƏllo', context_at(4).word.text
      assert.equal 'HƏllo', context_at(6).word.text
      assert.equal '', context_at(8).word.text
      assert.equal '', context_at(9).word.text
      assert.equal 'said', context_at(14).word.text
      assert.equal 'Mr', context_at(16).word.text
      assert.equal 'Bačon', context_at(19).word.text

      b.text = 'first'
      assert.equal 'first', context_at(1).word.text

    it "the word boundaries are determined using the mode variable word_pattern", ->
      b.mode = word_pattern: r'[Əl]+'
      assert.equal 'Əll', context_at(3).word.text

      b.mode = word_pattern: r'["Ə\\w]+'
      assert.equal '"HƏllo"', context_at(3).word.text
      assert.equal '"HƏllo"', context_at(8).word.text -- after "
      assert.equal '', context_at(9).word.text -- after ','

  it ".word_prefix holds the words's text up until pos", ->
    assert.equal '', context_at(2).word_prefix
    assert.equal 'HƏ', context_at(4).word_prefix

  it ".word_suffix holds the words's text after and including pos", ->
    assert.equal 'HƏllo', context_at(2).word_suffix
    assert.equal 'llo', context_at(4).word_suffix

  describe '.token', ->
    it 'is the grouping of similar characters', ->
      b.text = '@!?45xx __'
      assert.equal '@!?', context_at(1).token.text
      assert.equal '@!?', context_at(3).token.text
      assert.equal '45xx', context_at(4).token.text

    it 'is empty when looking at a blank', ->
      b.text = ' 2 '
      assert.is_true context_at(1).token.empty
      assert.is_true context_at(3).token.empty

  it ".prefix holds the line's text up until pos", ->
    assert.equal '', context_at(1).prefix
    assert.equal '"HƏllo", said Mr.Bačon', context_at(#b + 1).prefix
    assert.equal '"H', context_at(3).prefix

  it ".suffix holds the line's text after and including pos", ->
    assert.equal '', context_at(#b + 1).suffix
    assert.equal '"HƏllo", said Mr.Bačon', context_at(1).suffix
    assert.equal 'Mr.Bačon', context_at(15).suffix

  it '.next_char holds the current character or the empty string if none', ->
    assert.equal 'Ə', context_at(3).next_char
    assert.equal '', context_at(#b + 1).next_char

  it '.prev_char holds the previous character or the empty string if none', ->
    assert.equal 'Ə', context_at(4).prev_char
    assert.equal '', context_at(1).prev_char

  it '.line holds the current line object', ->
    assert.equal b.lines[1], context_at(1).line

  it '.style holds the style at point, if any', ->
    buf = ActionBuffer!
    buf\append '[', 'operator'
    buf\append '"foo"', 'string'
    buf\append ' normal'
    assert.equal 'operator', BufferContext(buf, 1).style
    assert.equal 'string', BufferContext(buf, 2).style
    assert.is_nil BufferContext(buf, 7).style

  it 'contexts are equal for the same buffer and pos', ->
    assert.equal context_at(2), context_at(2)
    assert.not_equal context_at(2), context_at(4)
