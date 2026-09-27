-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{
  for_file: (file) ->
    path = file.path\gsub '[^%w/%-%._~]', (c) -> string.format('%%%02X', c\byte!)
    "file://#{path}"

  to_path: (uri) ->
    path = uri\match '^file://(.*)$'
    path and path\gsub('%%(%x%x)', (hex) -> string.char(tonumber hex, 16))
}
