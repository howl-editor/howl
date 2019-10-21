-- Copyright 2019 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

class LineItem
  new: (@line) =>
  display_row: => {@line.nr, @line.chunk}
  preview: => chunk: @line.chunk

class LinesExplorer
  new: (@lines) =>
  display_path: => ''
  display_columns: => {{style:'comment', align: 'right'}, {}}
  display_items: =>
    lines = [LineItem line for line in *@lines]
    return lines, preserve_order: true
