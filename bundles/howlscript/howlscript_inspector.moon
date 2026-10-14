-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- Reports what keeps the buffer from compiling. The compiler stops at the first
-- error, so there's at most one.

howlscript = require 'howlscript'

(buffer) ->
  ok, lua, _, err = pcall howlscript.to_lua, buffer.text

  unless ok
    return {{
      line: 1
      type: 'error'
      message: "Howlscript compiler error: #{lua}"
    }}

  return {} if lua

  {{
    line: err.line
    byte_start_col: err.col
    -- without a known length, a single character is marked
    byte_end_col: err.col + (err.len or 1)
    type: 'error'
    message: err.message
  }}
