-- Copyright 2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

append = table.insert
json = bundle_load 'json'

(output) ->
  inspections = {}

  -- the output of cargo is technically not valid json
  -- they just dump one object after the other
  -- this converts them into an array, so the decoder understands...
  array = '[' .. output\gsub('%}%s*%{','}, {') .. ']'
  items = json.decode array

  for item in *items
    if item.message and
      (item.message.level == 'error' or
      item.message.level == 'warning') and
      item.message.code and
      item.message.spans
      for span in *item.message.spans
        inspection =
          line: span.line_start,
          type: item.message.level,
          search: span.text.text,
          message: span.label or item.message.message,
          start_col: span.column_start,
          end_col: span.column_end,
          byte_start_col: span.byte_start,
          byte_end_col: span.byte_end

        append inspections, inspection

  inspections



