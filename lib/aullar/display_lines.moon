-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

flair = require 'aullar.flair'
{:define_class} = require 'aullar.util'
styles = require 'aullar.styles'
Styling = require 'aullar.styling'
Pango = require 'ljglibs.pango'
Layout = Pango.Layout
pango_cairo = Pango.cairo
flair = require 'aullar.flair'

{:max, :min, :floor} = math
{:copy} = moon

flair.define_default 'indentation_guide', {
  type: flair.PIPE,
  foreground: '#aaaaaa',
  line_type: 'dotted'
  line_width: 1
}

flair.define_default 'edge_line', {
  type: flair.PIPE,
  foreground: '#aa0000',
  foreground_alpha: 0.2,
  line_width: 1
}

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
    if next_d_line
      block = if next_d_line._block
        next_d_line._block
      elseif next_d_line._full_background
        scan_block display_lines, d_line

  block.width = max(block.width, d_line.width) if block
  block

get_flairs = (buffer, line, display_line) ->
  start_offset = line.start_offset

  translate = (m) ->
    f = copy m
    f.start_offset = max 1, (f.start_offset - start_offset) + 1
    f.end_offset = (f.end_offset - start_offset) + 1
    f.flair = flair.compile f.flair, f.start_offset, f.end_offset, display_line
    f

  markers = buffer.markers\for_range start_offset, line.end_offset
  markers = [translate(m) for m in *markers when m.flair]
  markers

get_indent = (view, line) ->
  ptr = line.ptr
  spaces = 0
  tabs = 0

  for i = 0, line.size - 1
    c = ptr[i]
    if c == 0x20
      spaces += 1
    elseif c == 0x9
      tabs += 1
    else
      break

  spaces + tabs * view.config.view_tab_size

draw_indentation_guides = (x, y, base_x, line, cr, config, width_of_space) ->
  indent = line.indent
  view_indent = config.view_indent
  prev_indent = line.prev and line.prev.indent

  if line.size == 0
    return unless prev_indent and prev_indent > view_indent
    next_indent = line.next and line.next.indent
    return unless next_indent and next_indent > view_indent
    indent = min prev_indent, next_indent

  guide_x = x
  indentation_flair = flair.get 'indentation_guide'

  for i = 1, (indent / view_indent) - 1
    guide_x += width_of_space * view_indent
    adjusted_x = guide_x - base_x
    continue if adjusted_x < 0
    f = flair.get("indentation_guide_#{i}") or indentation_flair
    cr\save!
    f\draw adjusted_x, y, f.line_width or 0.5, line.height, cr
    cr\restore!

draw_edge_line = (at_col, x, y, base_x, line, cr, width_of_space) ->
  x += (width_of_space * at_col) - base_x
  if x > 0
    cr\save!
    f = flair.get "edge_line"
    f\draw x, y, f.line_width or 0.5, line.height, cr
    cr\restore!

DisplayLine = define_class {
  new: (@display_lines, @view, buffer, @pango_context, line) =>
    @layout = Layout pango_context
    @layout\set_text line.ptr, line.size
    @layout.tabs = display_lines.tab_array
    @nr = line.nr
    @size = line.size
    @indent = get_indent view, line
    @styling = buffer.styling\get(line.start_offset, line.end_offset)
    @layout.attributes = styles.get_attributes @styling, line.size

    width, height = @layout\get_pixel_size!
    @y_offset = floor @view.config.view_line_padding
    @text_height = height
    @height = height + @y_offset * 2
    @width = width + view.cursor.width
    @flairs = get_flairs buffer, line, @

    @background_ranges = parse_background_ranges @styling

    if #@background_ranges == 1
      range = @background_ranges[1]
      @_full_background = range.start_offset == 1 and range.end_offset > line.full_size

  properties: {
    block: =>
      if not @_block and @_full_background
        @_block = get_block @display_lines, @

      @_block

    prev: =>
      @nr > 1 and @display_lines[@nr - 1] or nil

     next: =>
      @display_lines[@nr + 1]
   }

  draw: (x, y, cr, clip, opts = {}) =>
    base_x = @view.base_x
    block = @block

    for bg_range in *@background_ranges
      width = block and block.width and block.width - base_x or nil
      bg_flair = flair.build {
        type: flair.RECTANGLE,
        background: bg_range.style.background
        background_alpha: 0.3
        :width
      }
      flair.draw bg_flair, @, bg_range.start_offset, bg_range.end_offset, x, y, cr

    if base_x > 0
      cr\save!
      cr\rectangle x, y, clip.x2 - x, clip.y2
      cr\clip!

    cr\move_to x - base_x, y + @y_offset
    pango_cairo.show_layout cr, @layout

    for f in *@flairs
      flair.draw f.flair, @, f.start_offset, f.end_offset, x, y, cr

    if opts.config.view_show_indentation_guides
      draw_indentation_guides x, y, base_x, @, cr, opts.config, opts.width_of_space

    edge_column = opts.config.view_edge_column
    if edge_column and edge_column > 0
      draw_edge_line edge_column, x, y, base_x, @, cr, opts.width_of_space

    cr\restore! if base_x > 0
}

(view, tab_array, buffer, pango_context) ->
  setmetatable {
    max: 0
    tab_array: tab_array
  }, {
    __index: (nr) =>
      line = buffer\get_line nr
      return nil unless line
      d_line = DisplayLine @, view, buffer, pango_context, line
      @max = max @max, nr
      rawset @, nr, d_line
      d_line
  }
