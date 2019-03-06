-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

append = table.insert
json = bundle_load 'json'

(cargo_output) ->
  inspections = {}

  -- the output of cargo is technically not valid json
  -- they just dump one object after the other
  -- this converts them into an array, so the decoder understands...
  array = '[' .. cargo_output\gsub('%}%s*%{','}, {') .. ']'
  items = json.decode array

  for item in *items
    message = item.message
    if item.reason == 'compiler-message' and
      message and
      (message.level == 'error' or message.level == 'warning') and
      message.spans
      for span in *message.spans
        inspection =
          line: span.line_start
          type: message.level
          search: span.text.text
          message: message.rendered
          start_col: span.column_start
          end_col: span.column_end
          byte_start_col: span.byte_start
          byte_end_col: span.byte_end
        append inspections, inspection

  inspections
