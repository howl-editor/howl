import Buffer, BufferContext from howl
import ActionBuffer from howl.ui

require 'howl.variables.core_variables'

describe 'BufferContext', ->
  local b

  before_each ->
    b = Buffer!
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

    it "the word boundaries are determined using the variable word_pattern", ->
      b.config.word_pattern = '[Əl]+'
      assert.equal 'Əll', context_at(3).word.text

      b.config.word_pattern = '["Ə%w]+'
      assert.equal '"HƏllo"', context_at(3).word.text
      assert.equal '"HƏllo"', context_at(8).word.text -- after "
      assert.equal '', context_at(9).word.text -- after ','

    it "the word_pattern can be a regex", ->
      b.config.word_pattern = r'\\pL+'
      assert.equal 'HƏllo', context_at(3).word.text

  it ".word_prefix holds the words's text up until pos", ->
    assert.equal '', context_at(2).word_prefix
    assert.equal 'HƏ', context_at(4).word_prefix

  it ".word_suffix holds the words's text after and including pos", ->
    assert.equal 'HƏllo', context_at(2).word_suffix
    assert.equal 'llo', context_at(4).word_suffix

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
