-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- LSP severities: 1 = error, 2 = warning, 3 = information, 4 = hint
type_for = (severity) ->
  (severity == nil or severity == 1) and 'error' or 'warning'

-- converts LSP diagnostics to inspection items (see howl.inspect). Positions
-- use the utf-8 encoding, so characters are byte columns.
to_items = (diagnostics) ->
  items = {}
  for d in *diagnostics
    first, last = d.range.start, d.range['end']
    message = d.message
    code = d.code
    if (type(code) == 'string' and code != '') or type(code) == 'number'
      message ..= " [#{code}]"

    items[#items + 1] = {
      line: first.line + 1,
      byte_start_col: first.character + 1,
      end_line: last.line + 1,
      byte_end_col: last.character + 1,
      type: type_for(d.severity),
      :message
    }
  items

:to_items
