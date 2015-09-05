-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

View = require 'aullar.view'
Buffer = require 'aullar.buffer'
styles = require 'aullar.styles'
DisplayLines = require 'aullar.display_lines'

ffi = require 'ffi'

describe 'DisplayLines', ->

  local view, buffer, display_lines

  setup ->
    styles.define 'b1', background: '#112233'
    styles.define 'b2', background: '#445566'
    styles.define 'b3', background: '#112233'

  before_each ->
    buffer = Buffer!
    view = View buffer
    display_lines = view.display_lines

  context '(one individual line)', ->
    describe 'background_ranges(line)', ->
      it 'returns ranges along with the style definition for styles runs with backgrounds', ->
        buffer.text = 'back to back'
        buffer.styling\set 1, 4, 'b1'
        buffer.styling\set 9, 12, 'b2'

        ranges = display_lines[1].background_ranges
        assert.equals 2, #ranges
        assert.same { start_offset: 1, end_offset: 5, style: { background: '#112233' } }, ranges[1]
        assert.same { start_offset: 9, end_offset: 13, style: { background: '#445566' } }, ranges[2]

      it 'merges adjacent ranges', ->
        buffer.text = 'background'
        buffer.styling\set 1, 5, 'b1'
        buffer.styling\set 5, 10, 'b3'

        ranges = display_lines[1].background_ranges
        assert.equals 1, #ranges
        assert.same { start_offset: 1, end_offset: 11, style: { background: '#112233' } }, ranges[1]

    describe '.indentation', ->
      it 'is the indentation level for the line', ->
        buffer.text = "zero\n  two\n    four\n\ttab\n"
        view.config.view_tab_size = 5

        assert.equals 0, display_lines[1].indent
        assert.equals 2, display_lines[2].indent
        assert.equals 4, display_lines[3].indent
        assert.equals 5, display_lines[4].indent

  context 'display blocks', ->
    it 'multiple adjacent lines with whole-line backgrounds are part of a single block', ->
      --                     8        16       24
      buffer.text = 'before\nblock 1\nblock 2\nafter'
      buffer.styling\set 1, 6, 'b1' -- styled up until eol
      buffer.styling\set 8, 23, 'b2' -- styled over eols
      assert.is_nil display_lines[1].block
      assert.is_not_nil display_lines[2].block
      assert.is_not_nil display_lines[3].block
      assert.is_nil display_lines[4].block

      assert.equals display_lines[2].block, display_lines[3].block
      block = display_lines[2].block
      assert.equals 2, block.start_line
      assert.equals 3, block.end_line

    it 'a single line with a whole-line background does not belong to a block', ->
      --                     8       15
      buffer.text = 'before\nblock?\nafter'
      buffer.styling\set 8, 14, 'b2' -- styled over eols
      assert.is_nil display_lines[2].block

    it 'the width of a block is the width of the longest line', ->
      buffer.text = 'block 1\nblock 2 longer'
      buffer.styling\set 1, #buffer.text, 'b1'
      block = display_lines[1].block
      assert.not_equals display_lines[1].width, block.width
      assert.equals display_lines[2].width, block.width

    context 'block merging', ->
      before_each ->
        --                     8        16       24      31
        buffer.text = 'before\nblock 2\nblock 3\nblock4\nafter'
        buffer.styling\set 8, 30, 'b1'
        for nr = 1, 5
          display_lines[nr].block -- force block evaluation

      it 'finds and merges previous blocks, including intermediate lines', ->
        block = display_lines[2].block
        display_lines[3] = nil
        display_lines[4] = nil
        assert.equals block, display_lines[4].block
        assert.equals block, display_lines[3].block

      it 'finds and merges subsequent blocks, including intermediate lines', ->
        block = display_lines[4].block
        display_lines[2] = nil
        display_lines[3] = nil
        assert.equals block, display_lines[2].block
        assert.equals block, display_lines[3].block
