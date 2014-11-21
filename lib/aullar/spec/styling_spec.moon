-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

Buffer = require 'aullar.buffer'
Styling = require 'aullar.styling'

ffi = require 'ffi'

describe 'Styling', ->

  local buffer, styling

  before_each ->
    buffer = Buffer!
    styling = Styling buffer

  describe 'set(start_offset, end_offset, style)', ->
    it 'sets the specified style for the range [start_offset, end_offset)', ->
      buffer.text = 'a flair or two'
      styling\set 3, 8, 'keyword'
      assert.same { 3, 'keyword', 8 }, styling.lines[1]

    it 'allows the interval to span lines', ->
      buffer.text = '123\n56\n89'
      styling\set 2, 9, 'keyword'
      assert.same { 2, 'keyword', 5 }, styling.lines[1]
      assert.same { 1, 'keyword', 4 }, styling.lines[2]
      assert.same { 1, 'keyword', 2 }, styling.lines[3]

    it 'handles boundary conditions properly', ->
      buffer.text = '123\n56'
      styling\set 1, 4, 'keyword'
      assert.same { 1, 'keyword', 4 }, styling.lines[1]

      styling\set 1, 5, 'keyword'
      assert.same { 1, 'keyword', 5 }, styling.lines[1]

    it 'updates .last_line_styled to the last line styled', ->
      buffer.text = '123\n56\n89'
      assert.equals 0, styling.last_line_styled

      styling\set 1, 2, 'keyword'
      assert.equals 1, styling.last_line_styled

      styling\set 8, 9, 'keyword'
      assert.equals 3, styling.last_line_styled

      styling\set 6, 7, 'keyword'
      assert.equals 3, styling.last_line_styled

  describe 'invalidate_from(start_line)', ->
    it 'removes styling from <start_line> and forward', ->
      buffer.text = '123\n56\n89'
      styling\set 2, 9, 'keyword'
      styling\invalidate_from 3
      assert.same {}, styling.lines[3]
      assert.not_same {}, styling.lines[2]
      styling\invalidate_from 2
      assert.same {}, styling.lines[2]
      assert.not_same {}, styling.lines[1]
      styling\invalidate_from 1
      assert.same {}, styling.lines[1]

    it 'updates .last_line_styled', ->
      buffer.text = '123\n56\n89'
      styling\set 2, 9, 'keyword'
      styling\invalidate_from 3
      assert.equals 2, styling.last_line_styled

  describe 'style_to(to_line, lexer)', ->
    it 'styles from up to <to_line>', ->
      buffer.text = '123\n56\n89'
      lexer = spy.new -> {}
      styling\style_to 3, lexer
      assert.spy(lexer).was_called_with '123\n56\n89'

    it 'starts styling from .last_line_styled', ->
      buffer.text = '123\n56\n89'
      styling\set 1, 3, 'keyword'
      lexer = spy.new -> {}
      styling\style_to 3, lexer
      assert.spy(lexer).was_called_with '56\n89'

  describe 'at(line, col)', ->
    it 'returns the style at the specified position', ->
      buffer.text = '123\n5'
      styling\set 1, 2, 'keyword'
      styling\set 2, 5, 'string'
      styling\set 5, 6, 'operator'

      assert.equals 'keyword', styling\at 1, 1
      assert.equals 'string', styling\at 1, 2
      assert.equals 'string', styling\at 1, 4
      assert.equals 'operator', styling\at 2, 1

    it 'returns nil for out of boundary positions', ->
      buffer.text = '123\n5'
      styling\set 1, 4, 'keyword'
      assert.is_nil styling\at 1, 0
      assert.is_nil styling\at 1, 5
      assert.is_nil styling\at 2, 1

    it 'returns nil for unstyled positions', ->
      buffer.text = '123\n5'
      assert.is_nil styling\at 1, 0

    it 'allows for negative values of col, indexing backwards', ->
      buffer.text = '123\n5'
      styling\set 1, 4, 'keyword'
      styling\set 4, 5, 'string'
      assert.equals 'string', styling\at 1, -1
      assert.equals 'keyword', styling\at 1, -2

  describe 'at_offset(offset)', ->
    it 'returns the style at the specified offset', ->
      buffer.text = '123\n5'
      styling\set 1, 2, 'keyword'
      styling\set 2, 5, 'string'
      styling\set 5, 6, 'operator'

      assert.equals 'keyword', styling\at_offset 1
      assert.equals 'string', styling\at_offset 2
      assert.equals 'string', styling\at_offset 4
      assert.equals 'operator', styling\at_offset 5

  describe 'refresh_at(line_nr, to_line, lexer [, opts])', ->

    context 'and <offset> is not part of a block', ->
      it 'refreshes only the current line', ->
        buffer.text = '123\n56\n89\n'

        styling\apply 1, {
          1, 'keyword', 4,
          5, 'string', 7,
          8, 'string', 9,
        }

        lexer = spy.new -> { 1, 'operator', 2 }
        styling\refresh_at 2, 3, lexer

        assert.spy(lexer).was_called_with '56\n'
        assert.same { 1, 'operator', 2 }, styling.lines[2]

      it 'falls back to a full lexing if newly lexed line is part of a block', ->
        buffer.text = '123\n56\n'

        lexers = {
          spy.new -> { 1, 'string', 5 },
          spy.new -> { 1, 'string', 7 },
        }
        call_count = 1
        lexer = (text) ->
          l = lexers[call_count]
          call_count += 1
          l(text)

        styling\refresh_at 1, 3, lexer

        assert.spy(lexers[1]).was_called_with '123\n'
        assert.spy(lexers[2]).was_called_with '123\n56\n'
        assert.same { 1, 'string', 5 }, styling.lines[1]
        assert.same { 1, 'string', 3 }, styling.lines[2]

    context 'and <offset> is at the last line of a block', ->
      it 'starts from the first non-block line', ->
        buffer.text = '123\n56\n89\n'

        styling\apply 1, {
          1, 'keyword', 4,
          5, 'string', 10, -- block of line 2 & 3
        }

        lexer = spy.new -> { 1, 'operator', 6 }
        styling\refresh_at 3, 4, lexer

        assert.spy(lexer).was_called_with '56\n89\n'
        assert.same { 1, 'operator', 4 }, styling.lines[2]
        assert.same { 1, 'operator', 3 }, styling.lines[3]

    context 'and <offset> is at a line within a block', ->
      it 'only lexes up to the current line if the new styling ends in the same block style', ->
        buffer.text = '123\n56\n89\n'
        styling\set 1, 10, 'my_block'
        lexer = spy.new -> { 1, 'my_block', 8 }
        res = styling\refresh_at 2, 3, lexer
        assert.spy(lexer).was_called(1)
        assert.spy(lexer).was_called_with '123\n56\n'
        assert.same { start_line: 2, end_line: 2, invalidated: false }, res

      it 'lexes the full range if the new styling indicates a block change', ->
        buffer.text = '123\n56\n89\n'
        styling\set 1, 10, 'my_block'
        lexer = spy.new -> { 1, 'operator', 2 }
        res = styling\refresh_at 2, 3, lexer
        assert.spy(lexer).was_called(2)
        assert.spy(lexer).was_called_with '123\n56\n'
        assert.spy(lexer).was_called_with '123\n56\n89\n'
        assert.same { start_line: 2, end_line: 3, invalidated: true }, res

    it 'returns the styled range', ->
      buffer.text = '123\n56\n89\n'
      lexer = spy.new -> { 1, 'operator', 2 }
      res = styling\refresh_at 1, 3, lexer
      assert.same { start_line: 1, end_line: 1, invalidated: false }, res

    context 'when opts.force_full is set', ->
      it 'always lexes the full range', ->
        buffer.text = '123\n56\n89\n'
        lexer = spy.new -> { 1, 'operator', 2 }
        res = styling\refresh_at 1, 3, lexer, force_full: true
        assert.spy(lexer).was_called_with '123\n56\n89\n'
        assert.same { start_line: 1, end_line: 3, invalidated: true }, res


    context 'notifications', ->
      it 'fires the on_styled notification', ->
        listener = on_styled: spy.new ->
        buffer\add_listener listener
        buffer.text = '123\n56\n89\n'
        lexer = -> { 1, 'operator', 2 }
        styling\refresh_at 1, 3, lexer, force_full: true
        assert.spy(listener.on_styled).was_called_with listener, buffer, {
          start_line: 1, end_line: 3, invalidated: true
        }

      it 'sets the start offset from the first affected line regardless of the lexing', ->
        buffer.text = '123\n56\n89\n'
        styling\set 1, 6, 'string' -- block from 1st to 2nd line
        lexer = spy.new -> { 1, 'string', 7 }
        res = styling\refresh_at 2, 3, lexer
        assert.spy(lexer).was_called_with '123\n56\n' -- both lines lexer due to block
        -- but only the second line is effectively restyled
        assert.same { start_line: 2, end_line: 2, invalidated: false }, res

    it 'supresses the on_styled notification if opts.no_notify is set', ->
      listener = on_styled: spy.new ->
      buffer\add_listener listener
      buffer.text = '123\n56\n89\n'
      lexer = -> { 1, 'operator', 2 }
      styling\refresh_at 1, 3, lexer, force_full: true, no_notify: true
      assert.spy(listener.on_styled).was_not_called!

    context 'when lexing the full range', ->
      before_each ->
        buffer.text = '123\n56\n89\n'
        styling\set 1, 10, 'keyword'

      it 'invalidates all subsequent styling', ->
        lexer = -> { 1, 'operator', 2 }
        res = styling\refresh_at 1, 2, lexer, force_full: true
        assert.same {}, styling.lines[3]

      it 'sets last_line_styled to the last line styled', ->
        lexer = -> { 1, 'operator', 2 }
        styling\refresh_at 1, 2, lexer, force_full: true
        assert.equals 2, styling.last_line_styled

        styling\refresh_at 1, 3, lexer, force_full: true
        assert.equals 3, styling.last_line_styled

  describe 'apply(offset, styling)', ->
    it 'sets the styling for the relevant buffer portion', ->
      buffer.text = 'a flair or two'
      styling\apply 1, { 3, 'keyword', 8 }
      assert.same { 3, 'keyword', 8 }, styling.lines[1]

    it 'handles <offset> not being at the start of the line', ->
      buffer.text = 'not from\nwhence it commenced'
      styling\apply 5, { 1, 'keyword', 5 }
      styling\apply 10, { 8, 'string', 10 }
      assert.same { 5, 'keyword', 9 }, styling.lines[1]
      assert.same { 8, 'string', 10 }, styling.lines[2]

    it 'allows styling multiple lines in one call', ->
      buffer.text = 'style\nplease'
      styling\apply 3, { 1, 'string', 4, 6, 'comment', 8 } -- 'yle', 'le'
      assert.same { 3, 'string', 6 }, styling.lines[1]
      assert.same { 2, 'comment', 4 }, styling.lines[2]

    it 'handles some lines not being styled at all', ->
      buffer.text = '12\n456\n89'
      styling\apply 1, { 1, 'string', 2, 8, 'comment', 9 }
      assert.same { 1, 'string', 2 }, styling.lines[1]
      assert.same {}, styling.lines[2]
      assert.same { 1, 'comment', 2 }, styling.lines[3]

    context 'multi-line styling directives', ->
      it 'handles a style being extended over multiple lines', ->
        buffer.text = '12\n456\n89'
        styling\apply 1, { 2, 'string', 9 }
        assert.same { 2, 'string', 4 }, styling.lines[1]
        assert.same { 1, 'string', 5 }, styling.lines[2]
        assert.same { 1, 'string', 2 }, styling.lines[3]

      it 'handles a multi-line styling with offsets given', ->
        buffer.text = '12\n45\n7\n9'
        styling\apply 2, { 1, 'string', 7 }
        assert.same { 2, 'string', 4 }, styling.lines[1]
        assert.same { 1, 'string', 4 }, styling.lines[2]
        assert.same { 1, 'string', 2 }, styling.lines[3]

        styling\apply 4, { 1, 'operator', 5 } -- 2nd and 3rd line
        assert.same { 1, 'operator', 4 }, styling.lines[2]
        assert.same { 1, 'operator', 2 }, styling.lines[3]

        styling\apply 7, { 1, 'keyword', 4 } -- 2nd and 3rd line
        assert.same { 1, 'keyword', 3 }, styling.lines[3]
        assert.same { 1, 'keyword', 2 }, styling.lines[4]

    it 'handles merging of already existing styles', ->
      buffer.text = 'a style here'
      styling\apply 1, { 1, 'operator', 2 }
      styling\apply 1, { 9, 'string', 13 }
      assert.same { 1, 'operator', 2, 9, 'string', 13 }, styling.lines[1]
      styling\apply 1, { 3, 'string', 8 }
      assert.same { 1, 'operator', 2, 3, 'string', 8, 9, 'string', 13 }, styling.lines[1]

    it 'handles boundary conditions properly', ->
      buffer.text = '123\n56'
      styling\apply 1, { 1, 'keyword', 4 }
      assert.same { 1, 'keyword', 4 }, styling.lines[1]

      styling\apply 1, { 1, 'keyword', 5 }
      assert.same { 1, 'keyword', 5 }, styling.lines[1]

    it 'updates .last_line_styled', ->
      buffer.text = '123\n56\n89'
      assert.equals 0, styling.last_line_styled

      styling\apply 1, { 1, 'operator', 2 }
      assert.equals 1, styling.last_line_styled

      styling\apply 1, { 8, 'operator', 10 }
      assert.equals 3, styling.last_line_styled

      styling\apply 1, { 5, 'operator', 6 }
      assert.equals 3, styling.last_line_styled

    context 'sub lexing', ->
      it 'automatically styles using extended styles when requested', ->
        buffer.text = '>foo\nbar'
        styling\apply 1, {
          1, 'operator', 2,
          2, { 1, 's2', 2, 2, 's3', 3 }, 'my_sub|s1',
          4, 's2', 5
          6, { 1, 's2', 2 }, 'my_sub|s1',
        }
        assert.same {
          1, 'operator', 2,
          2, 's1:s2', 3,
          3, 's1:s3', 4,
          4, 's2', 5
        }, styling.lines[1]

        assert.same { 1, 's1:s2', 2 }, styling.lines[2]

      it 'styles any holes with the base style', ->
        buffer.text = '123\n5\n78'
        styling\apply 1, {
          1, { 2, 's3', 3, 7, 's4', 8 }, 'my_sub|s1'
        }
        assert.same {
          1, 's1', 2,
          2, 's1:s3', 3
          3, 's1', 5,
        }, styling.lines[1]

        assert.same {
          1, 's1', 3,
        }, styling.lines[2]

        assert.same {
          1, 's1:s4', 2
        }, styling.lines[3]

      it 'styles any unstyled line-sized holes with the base style', ->
        buffer.text = '1\n34\n67'
        styling\apply 1, {
          1, { 1, 's3', 7 }, 'my_sub|s1'
        }
        assert.same { 1, 's1:s3', 3 }, styling.lines[1]
        assert.same { 1, 's1:s3', 4 }, styling.lines[2]
        assert.same { 1, 's1:s3', 2 }, styling.lines[3]

      it 'accounts for the offset parameter', ->
        buffer.text = '1\n34\n67'
        styling\apply 3, {
          1, { 2, 's3', 3 }, 'my_sub|s1'
        }
        assert.same {
          1, 's1', 2,
          2, 's1:s3', 3
        }, styling.lines[2]

      it 'accounts for the offset of the embedded style', ->
        buffer.text = '1\n34\n67'
        styling\apply 1, {
          3, { 2, 's3', 3 }, 'my_sub|s1'
        }
        assert.same {
          1, 's1', 2,
          2, 's1:s3', 3
        }, styling.lines[2]

  describe 'reverse(start_offset, end_offset)', ->
    it 'returns a table of styles and positions for the given range, same as styles argument to apply', ->
      buffer.text = 'foo'
      styles = { 1, 's1', 2, 2, 's2', 4 }
      styling\apply 1, styles
      assert.same styles, styling\reverse(1, buffer.size)

    it 'handles multi-line ranges', ->
      buffer.text = '123\n56\n89'
      styles = { 1, 's1', 5, 5, 's2', 8, 8, 's3', 10 }
      styling\apply 1, styles
      assert.same styles, styling\reverse 1, buffer.size

    it 'handles gaps', ->
      buffer.text = '123\n56\n89'
      styles = { 2, 's1', 3, 9, 's2', 10 }
      styling\apply 1, styles
      assert.same styles, styling\reverse 1, buffer.size

    it 'end_pos is inclusive', ->
      buffer.text = 'foo'
      styles = { 1, 's1', 2, 2, 's2', 4 }
      styling\apply 1, styles
      assert.same { 1, 's1', 2 }, styling\reverse 1, 1

    it 'indexes are byte offsets', ->
      buffer.text = 'Liñe'
      styles = { 1, 's1', 2 }
      styling\apply 5, styles
      assert.same { 1, 's1', 2 }, styling\reverse 5, 5
