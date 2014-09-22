-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

View = require 'aullar.view'
Buffer = require 'aullar.buffer'
styles = require 'aullar.styles'
DisplayLine = require 'aullar.display_line'

ffi = require 'ffi'

describe 'DisplayLine', ->

  local buffer, view

  before_each ->
    buffer = Buffer!
    view = View buffer

  describe 'background_ranges(line)', ->
    it 'returns ranges along with the style definition for styles runs with backgrounds', ->
      styles.define 'b1', background: '#112233'
      styles.define 'b2', background: '#445566'
      buffer.text = 'back to back'
      buffer.styling\set 1, 5, 'b1'
      buffer.styling\set 9, 13, 'b2'

      dline = DisplayLine view, view.area.pango_context, buffer, buffer\get_line 1

      ranges = dline.background_ranges
      assert.equals 2, #ranges
      assert.same { start_offset: 1, end_offset: 5, style: { background: '#112233' } }, ranges[1]
      assert.same { start_offset: 9, end_offset: 13, style: { background: '#445566' } }, ranges[2]

    it 'merges adjacent ranges', ->
      styles.define 'b1', background: '#112233'
      styles.define 'b2', background: '#112233'
      buffer.text = 'background'
      buffer.styling\set 1, 5, 'b1'
      buffer.styling\set 5, 11, 'b2'

      dline = DisplayLine view, view.area.pango_context, buffer, buffer\get_line 1

      ranges = dline.background_ranges
      assert.equals 1, #ranges
      assert.same { start_offset: 1, end_offset: 11, style: { background: '#112233' } }, ranges[1]
