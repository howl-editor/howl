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

define_class {
  new: (@view, pango_context, buffer, @line) =>
    @layout = Layout pango_context
    @layout\set_text line.text, line.size
    styling = buffer.styling.lines[line.nr]
    @layout.attributes = styles.get_attributes styling

    width, height = @layout\get_pixel_size!
    @height = height
    @text_height = height
    @width = width + @view.cursor.width
    @background_ranges = parse_background_ranges styling

  draw: (x, y, cr, clip) =>
    base_x = @view.base_x

    for bg_range in *@background_ranges
      flair = Flair(Flair.RECTANGLE, {
        background: bg_range.style.background
        background_alpha: 0.3
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
