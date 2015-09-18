import Buffer from howl
import text from howl.editing

describe 'text', ->
  local buffer, lines
  before_each ->
    buffer = Buffer!
    lines = buffer.lines

  describe 'paragraph_at(line)', ->
    at = (nr) ->
      [l.nr for l in *text.paragraph_at lines[nr]]

    before_each ->
      buffer.text = 'one\n\nthree\nfour\n\n\nseven'

    it 'returns a list of lines composing the current paragraph', ->
      assert.same { 1 }, at 1
      assert.same { 3, 4 }, at 3
      assert.same { 3, 4 }, at 4
      assert.same { 7 }, at 7

    context 'when starting at an empty line', ->
      it 'returns the previous paragraph if present', ->
        assert.same { 1 }, at 2
        assert.same { 3, 4 }, at 5

      it 'returns the following paragraph if present', ->
        assert.same { 7 }, at 6

      it 'returns an empty list if no paragraph is found', ->
        buffer.text = 'one\n\n\n\nfive'
        assert.same {}, at 3

    it 'considers lines starting with blanks to be paragraph delimiters', ->
      buffer.text = 'trailing\n  indented start\ncontinued and ended here.\n  new para'
      assert.same { 2, 3 }, at 2

    it "calls and respects the mode's .is_paragraph_break() if present", ->
      buffer.mode = is_paragraph_break: (line) -> line\match '^-'
      buffer.text = 'before\n- new para\n  continued\n- next'
      assert.same { 2, 3 }, at 2

  describe 'can_reflow(line, limit)', ->
    it 'returns true if the line is longer than limit', ->
      buffer.text = 'too long'
      assert.is_true text.can_reflow lines[1], 6

    it 'returns true if the line can be combined with the previous one', ->
      buffer.text = 'itty\nbitty'
      assert.is_true text.can_reflow lines[2], 10

    it 'returns true if the line can be combined with the following one', ->
      buffer.text = 'itty\nbitty'
      assert.is_true text.can_reflow lines[1], 10

      buffer.text = 'itty bitty\nshort\nlong by itself'
      assert.is_true text.can_reflow lines[2], 10

    it 'returns false if the line can not be combined with the previous one', ->
      buffer.text = 'itty\nbitty'
      assert.is_false text.can_reflow lines[2], 9

    it 'returns false if the line can not be combined with the following one', ->
      buffer.text = 'itty\nbitty'
      assert.is_false text.can_reflow lines[1], 9

    it 'returns false if the line is one, unbreakable, word', ->
      buffer.text = 'imjustgoingtoramble\none'
      assert.is_false text.can_reflow lines[1], 10

    it 'returns true if the line is more than one word, the first being unbreakable', ->
      buffer.text = 'imjustgoingtoramble stopme\none'
      assert.is_true text.can_reflow lines[1], 10

    it 'returns false if an adjacent short line is blank', ->
      buffer.text = 'itty\n'
      assert.is_false text.can_reflow lines[1], 10

      buffer.text = '\nitty\n'
      assert.is_false text.can_reflow lines[2], 10

    context "when the buffer's mode provides line_is_reflowable method", ->
      it 'respects a negative answer from that', ->
        buffer.text = 'hum ho hi hi'
        line = lines[1]
        assert.is_true text.can_reflow line, 10
        buffer.mode.line_is_reflowable = -> true
        assert.is_true text.can_reflow line, 10
        buffer.mode.line_is_reflowable = -> false
        assert.is_false text.can_reflow line, 10

  describe 'reflow_paragraph_at(line, limit)', ->
    it 'splits lines to enforce at most <limit> columns', ->
      buffer.text = 'one two three four\n'
      assert.is_true text.reflow_paragraph_at lines[1], 10
      assert.equals 'one two\nthree four\n', buffer.text

    it 'splits lines as close to <limit> as possible, given non-breaking words', ->
      buffer.text = 'onetwo three four\n'
      assert.is_true text.reflow_paragraph_at lines[1], 5
      assert.equals 'onetwo\nthree\nfour\n', buffer.text

    it 'combines lines as necessary to match <limit>', ->
      buffer.text = 'one\ntwo\nthree\nfour\n'
      assert.is_true text.reflow_paragraph_at lines[1], 10
      assert.equals 'one two\nthree four\n', buffer.text

    it 'returns an unbreakable line as is if it can not reflow', ->
      buffer.text = 'onetwo\n'
      assert.is_false text.reflow_paragraph_at lines[1], 4
      assert.equals 'onetwo\n', buffer.text

    it 'does not require there to be any newline at the end of the paragraph', ->
      buffer.text = 'one two'
      assert.is_true text.reflow_paragraph_at lines[1], 5
      assert.equals 'one\ntwo', buffer.text

    it 'includes all the paragraph text in the reflowed text (boundary condition)', ->
      buffer.text = 'one t'
      assert.is_true text.reflow_paragraph_at lines[1], 4
      assert.equals 'one\nt', buffer.text

    it 'converts an overflowing space to an eol', ->
      buffer.text = 'one \n'
      assert.is_true text.reflow_paragraph_at lines[1], 3
      assert.equals 'one\n\n', buffer.text

    it 'does not modify the buffer unless there is a change', ->
      buffer.text = 'one two\n'
      buffer.modified = false
      assert.is_false text.reflow_paragraph_at lines[1], 10
      assert.is_false buffer.modified
