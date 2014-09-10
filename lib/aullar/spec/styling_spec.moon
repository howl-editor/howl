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

    it 'handles a style being extended over multiple lines', ->
      buffer.text = '12\n456\n89'
      styling\apply 1, { 2, 'string', 9 }
      assert.same { 2, 'string', 4 }, styling.lines[1]
      assert.same { 1, 'string', 5 }, styling.lines[2]
      assert.same { 1, 'string', 2 }, styling.lines[3]

    it 'handles merging of already existing styles', ->
      buffer.text = 'a style here'
      styling\apply 1, { 1, 'operator', 2 }
      styling\apply 1, { 9, 'string', 13 }
      assert.same { 1, 'operator', 2, 9, 'string', 13 }, styling.lines[1]
      styling\apply 1, { 3, 'string', 8 }
      assert.same { 1, 'operator', 2, 3, 'string', 8, 9, 'string', 13 }, styling.lines[1]

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
