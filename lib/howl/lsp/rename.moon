-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

lsp = require 'howl.lsp'
edits = require 'howl.lsp.edits'
references = require 'howl.lsp.references'
{:to_locations} = require 'howl.lsp.definition'

-- returns the document state of buffer if its server can rename, or nil and a
-- message
state_for = (buffer) ->
  state = lsp.attach buffer
  return nil, "No LSP server available for '#{buffer.title}'" unless state
  client = state.client
  if client.initialized and not client.capabilities.renameProvider
    return nil, "The LSP server for '#{buffer.title}' does not support renaming"
  state

-- returns the name of the symbol at pos, to offer when renaming it, or nil and
-- a message if it can't be renamed. Must be called from a coroutine.
prepare = (buffer, pos) ->
  state, err = state_for buffer
  return nil, err unless state

  word = buffer\context_at(pos).word.text
  provider = state.client.capabilities.renameProvider
  -- before the server is initialized, whether it can prepare isn't known
  unless type(provider) == 'table' and provider.prepareProvider
    return nil, 'Please position the cursor on a symbol' if word.is_empty
    return word

  lsp.sync buffer
  result, err = state.client\request 'textDocument/prepareRename', {
    textDocument: { uri: state.uri },
    position: lsp.position(buffer, pos)
  }
  return nil, err if err
  unless result
    return nil, word.is_empty and 'Nothing to rename at the cursor' or "'#{word}' can't be renamed"

  return result.placeholder if result.placeholder
  return word if result.defaultBehavior
  range = result.range or result
  buffer\sub lsp.pos_for(buffer, range.start), lsp.pos_for(buffer, range['end']) - 1

-- returns the places to rename for the symbol named name at pos, as locations
-- with the text of their lines, and the one at pos. They're the edits of a
-- rename to the same name, or the references with servers that don't answer
-- that (as zuban doesn't). Returns nil and a message if there are none. Must
-- be called from a coroutine.
preview_locations = (buffer, pos, name) ->
  state, err = state_for buffer
  return nil, err unless state

  lsp.sync buffer
  position = lsp.position buffer, pos
  result = state.client\request 'textDocument/rename', {
    textDocument: { uri: state.uri },
    :position,
    newName: name
  }
  docs = type(result) == 'table' and edits.documents_of(result) or {}
  locations = to_locations [{ uri: d.uri, range: e.range } for d in *docs for e in *d.edits], state.client.root
  if #locations > 0
    references.add_line_text locations
  else
    locations = references.locations_for(buffer, pos) or {}

  return nil, "Found no places to rename for '#{name}'" if #locations == 0

  table.sort locations, (a, b) ->
    return a.file.path < b.file.path if a.file != b.file
    return a.line_nr < b.line_nr if a.line_nr != b.line_nr
    a.byte_start_column < b.byte_start_column

  locations, references.location_at(locations, buffer.file, position)

-- renames the symbol at pos to new_name, applying the server's edit. Returns
-- the result of `edits.apply_workspace_edit`, or nil and an error. Must be
-- called from a coroutine.
rename = (buffer, pos, new_name) ->
  state, err = state_for buffer
  return nil, err unless state

  lsp.sync buffer
  result, err = state.client\request 'textDocument/rename', {
    textDocument: { uri: state.uri },
    position: lsp.position(buffer, pos),
    newName: new_name
  }
  return nil, err if err
  return nil, 'The server found nothing to rename' unless result
  edits.apply_workspace_edit result

:prepare, :preview_locations, :rename
