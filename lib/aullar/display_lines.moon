-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

{:define_class} = require 'aullar.util'
styles = require 'aullar.styles'
Pango = require 'ljglibs.pango'
Layout = Pango.Layout
pango_cairo = Pango.cairo
Flair = require 'aullar.flair'

{:max, :min} = math

parse_background_ranges = (styling) ->
  ranges = {}
  range = nil

  for i = 1, #styling - 2, 3
    def = styles.def_for styling[i + 1]
    if def and def.background
      start_offset = styling[i]
      end_offset = styling[i + 2]

      if range
        if range.end_offset == start_offset and range.style.background == def.background
          range.end_offset = end_offset
          continue
        else
          ranges[#ranges + 1] = range

      range = {
        start_offset: styling[i],
        end_offset: styling[i + 2],
        style: background: def.background
      }
    elseif range
      ranges[#ranges + 1] = range
      range = nil

  ranges[#ranges + 1] = range if range
  ranges

scan_block = (display_lines, d_line) ->
  block = width: d_line.width
  start_line = d_line
  cur_line = display_lines[d_line.nr - 1]

  while cur_line and cur_line._full_background
    start_line = cur_line
    block.width = max block.width, cur_line.width
    cur_line = display_lines[cur_line.nr - 1]

  block.start_line = start_line

  end_line = d_line
  cur_line = display_lines[d_line.nr + 1]

  while cur_line and cur_line._full_background
    end_line = cur_line
    block.width = max block.width, cur_line.width
    cur_line = display_lines[cur_line.nr + 1]

  block.end_line = end_line
  block.width += 5

  block

get_block = (display_lines, d_line) ->
  prev_d_line = display_lines[d_line.nr - 1]
  block = if prev_d_line
    if prev_d_line._block
      prev_d_line._block
    elseif prev_d_line._full_background
      return scan_block display_lines, d_line

  unless block
    next_d_line = display_lines[d_line.nr + 1]
    block = if next_d_line._block
      next_d_line._block
    elseif next_d_line._full_background
      scan_block display_lines, d_line

  block.width = max(block.width, d_line.width) if block
  block

DisplayLine = define_class {
  new: (@display_lines, @view, buffer, pango_context, @line) =>
    @layout = Layout pango_context
    @layout\set_text line.text, line.size
    @nr = line.nr
    styling = buffer.styling.lines[line.nr]
    @layout.attributes = styles.get_attributes styling

    width, height = @layout\get_pixel_size!
    @height = height
    @width = width + view.cursor.width
    @background_ranges = parse_background_ranges styling

    if #@background_ranges == 1
      range = @background_ranges[1]
      @_full_background = range.start_offset == 1 and range.end_offset > @line.full_size

  properties: {
    block: =>
      if not @_block and @_full_background
        @_block = get_block @display_lines, @

      @_block
   }


  draw: (x, y, cr, clip) =>
    base_x = @view.base_x
    block = @block

    for bg_range in *@background_ranges
      width = block and block.width and block.width - base_x or nil
      flair = Flair(Flair.RECTANGLE, {
        background: bg_range.style.background
        background_alpha: 0.3
        :width
      })
      flair\draw @, bg_range.start_offset, bg_range.end_offset, x, y, cr

    if base_x > 0
      cr\save!
      cr\rectangle x, y, clip.x2 - x, clip.y2
      cr\clip!

    cr\move_to x - base_x, y
    pango_cairo.show_layout cr, @layout
    cr\restore! if base_x > 0
}

(view, buffer, pango_context) ->
  setmetatable {
    max: 0
  }, {
    __index: (nr) =>
      line = buffer\get_line nr
      return nil unless line
      d_line = DisplayLine @, view, buffer, pango_context, line
      @max = max @max, nr
      rawset @, nr, d_line
      d_line
  }
