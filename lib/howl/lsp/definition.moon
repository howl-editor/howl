-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

lsp = require 'howl.lsp'
uri = require 'howl.lsp.uri'
{:File} = howl.io
{:markup} = howl.ui

-- converts a Location or LocationLink to a location for `app.open` and
-- `select_location`, or nil if it's not for a file. With the utf-8 encoding a
-- position's character is a byte offset within the line.
to_location = (loc, root) ->
  target = loc.targetUri or loc.uri
  path = target and uri.to_path target
  return nil unless path

  file = File path
  range = loc.targetSelectionRange or loc.range
  start, stop = range.start, range['end']
  line_nr = start.line + 1
  byte_column = start.character + 1
  where = root and file\relative_to_parent(root) or file.short_path
  {
    markup.howl "<comment>#{where}</>:<number>#{line_nr}</>"
    :file,
    :line_nr,
    :byte_column,
    byte_start_column: byte_column,
    byte_end_column: stop.line == start.line and stop.character + 1 or byte_column
  }

-- converts a definition result, which is either a Location, a list of
-- Locations or a list of LocationLinks, to a list of locations. Paths are
-- shown relative to root when below it. Servers can list the same location
-- more than once (zuban does for some method calls), so duplicates are
-- dropped.
to_locations = (result, root) ->
  return {} unless type(result) == 'table'
  result = { result } if result.uri
  locations = {}
  seen = {}
  for loc in *result
    location = to_location loc, root
    if location
      key = "#{location.file}:#{location.line_nr}:#{location.byte_column}"
      unless seen[key]
        seen[key] = true
        table.insert locations, location
  locations

-- returns a list of the server's locations for pos from method, a request
-- answered with locations ('definition', 'declaration', 'typeDefinition' or
-- 'implementation'). Returns nil if there's no server supporting it or it found
-- none. Must be called from a coroutine.
locations_for = (buffer, pos, method = 'definition') ->
  state = lsp.attach buffer
  return nil unless state
  client = state.client
  return nil if client.initialized and not client.capabilities["#{method}Provider"]

  lsp.sync buffer
  result = client\request "textDocument/#{method}", {
    textDocument: { uri: state.uri },
    position: lsp.position(buffer, pos)
  }
  locations = to_locations result, client.root
  #locations > 0 and locations or nil

:to_locations, :locations_for
