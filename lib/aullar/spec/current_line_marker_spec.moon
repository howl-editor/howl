-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

View = require 'aullar.view'
Buffer = require 'aullar.buffer'
flair = require 'aullar.flair'
CurrentLineMarker = require 'aullar.current_line_marker'
{:RGBA} = require 'ljglibs.gdk'

describe 'CurrentLineMarker', ->
  local view, drawn, cr

  before_each ->
    view = View Buffer 'current line'
    drawn = rectangles: {}
    -- records what's drawn instead of drawing it
    cr = {
      clip_extents: { x1: 0, y1: 0, x2: 300, y2: 100 }
      save: =>
      restore: =>
      fill: =>
      rectangle: (x, y, width) => table.insert drawn.rectangles, { :x, :width }
      set_source_rgb: (r, g, b) => drawn.color = { r, g, b }
      set_source_rgba: (r, g, b) => drawn.color = { r, g, b }
    }

  after_each -> flair.set_theme {}

  describe 'draw_before(x, y, display_line, cr, col)', ->
    it 'draws a themed current_line flair across the full width', ->
      flair.set_theme current_line: { type: flair.RECTANGLE, background: '#112233' }
      CurrentLineMarker(view)\draw_before 0, 0, view.display_lines[1], cr, 1

      assert.same { { x: 0, width: 300 } }, drawn.rectangles
      c = RGBA '#112233'
      assert.same { c.red, c.green, c.blue }, drawn.color
