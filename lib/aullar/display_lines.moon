-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

flair = require 'aullar.flair'
{:define_class} = require 'aullar.util'
styles = require 'aullar.styles'
Pango = require 'ljglibs.pango'
{:Layout, :AttrList, :SCALE} = Pango
pango_cairo = Pango.cairo
flair = require 'aullar.flair'

{:rawset, :rawget} = _G
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

styles.define_default 'blob', 'embedded:preproc'
styles.define_default 'wrap_indicator', 'comment'

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
        style:
          background: def.background
          alpha: def.background_alpha or 1
      }
    elseif range
      ranges[#ranges + 1] = range
      range = nil

  ranges[#ranges + 1] = range if range
  ranges

BlockMt = {
  __tostring: =>
    "Block##{@id}<start_line: #{@start_line}, end_line: #{@end_line}, width: #{@width}"
}

block_id = 0
get_block = (display_lines, d_line) ->
  local block
  start_line = d_line

  -- scan back
  cur_line = display_lines[d_line.nr - 1]
  while cur_line and cur_line._full_background
    if cur_line._block
      block = cur_line._block
      break

    start_line = cur_line
    cur_line = display_lines[cur_line.nr - 1]

  if block
    -- we found an earlier block, now extend it as neccessary down
    -- until the current line and then we're done
    cur_line = display_lines[min(block.end_line + 1, d_line.nr)]
    while cur_line and cur_line.nr <= d_line.nr
      cur_line._block = block
      block.width = max block.width, cur_line.width
      cur_line = display_lines[cur_line.nr + 1]

    block.end_line = max(block.end_line, d_line.nr)
    return block

  -- no block found looking back, scan forward
  end_line = d_line
  cur_line = display_lines[d_line.nr + 1]

  while cur_line and cur_line._full_background
    if cur_line._block
      block = cur_line._block

      -- we found a subsequent block, now extend it as neccessary up
      -- until the start line and then we're done
      cur_line = display_lines[cur_line.nr - 1]
      while cur_line and cur_line.nr >= start_line.nr
        cur_line._block = block
        block.width = max block.width, cur_line.width
        cur_line = display_lines[cur_line.nr - 1]

      return block

    end_line = cur_line
    cur_line = display_lines[cur_line.nr + 1]

  -- no existing block found, create a new one if unless this is a single
  -- line and assign it to the affected lines
  if start_line.nr != end_line.nr
    block_id += 1
    block = setmetatable {
      id: block_id,
      start_line: start_line.nr,
      end_line: end_line.nr,
      width: 0
    }, BlockMt
    cur_line = start_line
    while cur_line and cur_line.nr <= end_line.nr
      cur_line._block = block
      block.width = max block.width, cur_line.width
      cur_line = display_lines[cur_line.nr + 1]

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
  height = line.height
  if line.is_wrapped
    height = line.lines[1].extents.height

  for i = 1, (indent / view_indent) - 1
    guide_x += width_of_space * view_indent
    adjusted_x = guide_x - base_x
    continue if adjusted_x < 0
    f = flair.get("indentation_guide_#{i}") or indentation_flair
    cr\save!
    f\draw adjusted_x, y, f.line_width or 0.5, height, cr
    cr\restore!

draw_edge_line = (at_col, x, y, base_x, line, cr, width_of_space) ->
  x += (width_of_space * at_col) - base_x
  if x > 0
    cr\save!
    f = flair.get "edge_line"
    f\draw x, y, f.line_width or 0.5, line.height, cr
    cr\restore!

LinesMt = {
  at: (col) =>
    for line in *@
      if col >= line.line_start and col <= line.line_end
        return line

    nil

  at_pixel_y: (y) =>
    cur_y = 0
    for line in *@
      cur_y += line.height
      if cur_y > y
        return line

    nil
}

DisplayLine = define_class {
  new: (@display_lines, @view, buffer, @pango_context, line, width) =>
    @layout = Layout pango_context
    @layout\set_text line.ptr, line.size
    @layout.tabs = display_lines.tab_array
    @nr = line.nr
    @size = line.size
    @indent = get_indent view, line
    @width_of_space = @view.width_of_space

    config = view.config
    wrap = config.view_line_wrap

    WRAP_LIMIT = 2000 -- xxx replace
    if wrap != 'none' and @size <= WRAP_LIMIT
      wrap_indicator = @display_lines.wrap_indicator
      width = view.edit_area_width - wrap_indicator.width - @width_of_space
      @layout.width = width * SCALE
      wrap_mode = wrap == 'word' and Pango.WRAP_WORD or Pango.WRAP_CHAR
      @layout.wrap = wrap_mode
      @layout.spacing = (config.view_line_padding * 2) * SCALE

    @styling = buffer.styling\get(line.start_offset, line.end_offset)
    -- complexity sanity check before asking Pango to determine extents,
    -- as it will happily block seemingly for ever if someone manages
    -- to cram an entire app into one line (e.g. minimized JS)
    if #@styling > 2000
      @styling = { 1, 'blob', line.size + 1 }

    attributes = styles.get_attributes @styling, line.size

    @layout.attributes = attributes
    width, height = @layout\get_pixel_size!
    @y_offset = floor config.view_line_padding
    @text_height = height
    @height = height + @y_offset * 2
    @width = width + view.cursor.width
    @is_wrapped = @layout.is_wrapped
    @line_count = @layout.line_count

    @background_ranges = parse_background_ranges @styling

    if #@background_ranges > 0
      range = @background_ranges[1]
      full = range.start_offset == 1
      for i = 2, #@background_ranges
        r = @background_ranges[i]
        full and= r.start_offset == range.end_offset
        break unless full
        range = r

      @_full_background = full and range.end_offset > line.full_size

  properties: {
    block: =>
      if not @_block and @_full_background
        @_block = get_block @display_lines, @

      @_block

    prev: =>
      @nr > 1 and @display_lines[@nr - 1] or nil

    next: =>
      @display_lines[@nr + 1]

    lines: =>
      unless @_lines
        @_lines = {}
        iter = @layout.iter
        nr = 1
        while true
          layout_line = iter.line_readonly
          _, extents = layout_line\get_pixel_extents!
          line_start = layout_line.start_index + 1
          line_end = layout_line.length + line_start
          line_end -= 1 unless iter.at_last_line
          @_lines[#@_lines + 1] = {
            :nr,
            :line_start,
            :line_end,
            :extents,
            baseline: iter.baseline / SCALE
            height: extents.height + @y_offset * 2
          }
          nr += 1
          break unless iter\next_line!

        setmetatable @_lines, __index: LinesMt

      @_lines
   }

  refresh: =>
    @_flairs = nil

  draw: (x, y, cr, clip, opts = {}) =>
    base_x = @view.base_x
    block = @block
    @_flairs or= get_flairs opts.buffer, opts.line, @

    for i, bg_range in ipairs @background_ranges
      width = nil
      if i == 1 and block and block.width
        width = block.width - base_x

      bg_flair = flair.build {
        type: flair.RECTANGLE,
        background: bg_range.style.background
        background_alpha: bg_range.style.alpha
        :width
      }
      flair.draw bg_flair, @, bg_range.start_offset, bg_range.end_offset, x, y, cr

    if base_x > 0
      cr\save!
      cr\rectangle x, y, clip.x2 - x, clip.y2
      cr\clip!

    cr\move_to x - base_x, y + @y_offset
    pango_cairo.show_layout cr, @layout

    for f in *@_flairs
      flair.draw f.flair, @, f.start_offset, f.end_offset, x, y, cr

    if opts.config.view_show_indentation_guides
      draw_indentation_guides x, y, base_x, @, cr, opts.config, @width_of_space

    edge_column = opts.config.view_edge_column
    if edge_column and edge_column > 0
      draw_edge_line edge_column, x, y, base_x, @, cr, @width_of_space

    -- line wrap indicators
    if @is_wrapped
      wrap_indicator = @display_lines.wrap_indicator
      cr\save!
      wrap_y_offset = @y_offset
      max_x = (@layout.width / SCALE) + base_x
      for line in *@lines
        break if line.nr == @line_count
        wrap_y = y + wrap_y_offset
        indicator_x = min max_x, line.extents.width + @width_of_space / 2
        line_y_offset = (line.extents.height - wrap_indicator.height) / 2
        cr\move_to x - base_x + indicator_x, wrap_y + line_y_offset
        pango_cairo.show_layout cr, wrap_indicator.layout
        wrap_y_offset += line.extents.height + (@y_offset * 2)

      cr\restore!

    cr\restore! if base_x > 0
}

get_wrap_indicator = (pango_context, view) ->
  layout = Layout pango_context
  layout\set_text view.config.view_line_wrap_symbol

  list = AttrList()
  styles.apply list, 'wrap_indicator'
  layout.attributes = list
  width, height = layout\get_pixel_size!

  :layout, :width, :height

(view, tab_array, buffer, pango_context) ->
  setmetatable {
    min: math.huge
    max: 0
    tab_array: tab_array,
    wrap_indicator: get_wrap_indicator pango_context, view
    window: {}
    set_window: (first, last) =>
      w_size = (last - first) + 1
      edge = floor w_size / 4
      first = max 1, first - edge
      last = last + edge

      for i = @min, first - 1
        l = rawget @, i
        @[i] = nil if l and not l._block

      for i = last, @max
        l = rawget @, i
        @[i] = nil if l and not l._block

      @window = :first, :last, size: (last - first) + 1
      @min = max first, @min
      @max = min last, @max

  }, {
    __index: (nr) =>
      line = buffer\get_line nr
      return nil unless line
      d_line = DisplayLine @, view, buffer, pango_context, line
      @min = min @min, nr
      @max = max @max, nr
      outside = @window.size and (nr < @window.first or nr > @window.last)
      if not outside
        rawset @, nr, d_line

      d_line
  }
