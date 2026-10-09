-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

lsp = require 'howl.lsp'
{:to_locations} = require 'howl.lsp.definition'
{:app} = howl

-- returns a function giving the text of a line in file. An open buffer is read
-- rather than the file, since the server's positions are for the buffer text.
line_reader = (file) ->
  for b in *app.buffers
    if b.file == file
      return (nr) ->
        line = b.lines[nr]
        line and line.text

  ok, lines = pcall -> file.lines
  lines = {} unless ok
  (nr) -> lines[nr]

-- adds the text of each location's line as a second column, with the
-- reference highlighted
add_line_text = (locations) ->
  readers = {}
  for loc in *locations
    path = loc.file.path
    readers[path] or= line_reader loc.file
    loc[2] = readers[path](loc.line_nr) or ''
    if loc.byte_end_column > loc.byte_start_column
      loc.item_highlights = {
        nil,
        { { byte_start_column: loc.byte_start_column, byte_end_column: loc.byte_end_column } }
      }

-- returns a list of the server's references to the symbol at pos, including
-- its declaration, and the reference at pos if listed. Returns nil if there's
-- no server supporting it or it found none. Must be called from a coroutine.
locations_for = (buffer, pos) ->
  state = lsp.attach buffer
  return nil unless state
  client = state.client
  return nil if client.initialized and not client.capabilities.referencesProvider

  lsp.sync buffer
  position = lsp.position buffer, pos
  result = client\request 'textDocument/references', {
    textDocument: { uri: state.uri },
    :position,
    context: { includeDeclaration: true }
  }
  locations = to_locations result, client.root
  return nil if #locations == 0

  add_line_text locations
  line_nr, column = position.line + 1, position.character + 1
  for loc in *locations
    if loc.file == buffer.file and loc.line_nr == line_nr and
        loc.byte_start_column <= column and column <= loc.byte_end_column
      return locations, loc

  locations

:locations_for
