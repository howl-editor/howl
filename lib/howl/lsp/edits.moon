-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

lsp = require 'howl.lsp'
uri = require 'howl.lsp.uri'
{:app, :mode, :signal} = howl
{:File} = howl.io
append = table.insert

-- resolves edits, a list of TextEdits, to character ranges in buffer, ordered
-- by position. Their positions are all for the text before any of them are
-- applied, and inserts at the same position keep their order. Returns nil and
-- an error for overlapping edits.
resolve = (buffer, edits) ->
  ranges = for i, edit in ipairs edits
    {
      start: lsp.pos_for(buffer, edit.range.start),
      stop: lsp.pos_for(buffer, edit.range['end']),
      text: edit.newText or '',
      :i
    }

  table.sort ranges, (a, b) ->
    return a.start < b.start if a.start != b.start
    return a.stop < b.stop if a.stop != b.stop
    a.i < b.i

  for j, r in ipairs ranges
    return nil, "invalid edit range in '#{buffer.title}'" if r.stop < r.start
    if j > 1 and r.start < ranges[j - 1].stop
      return nil, "overlapping edits in '#{buffer.title}'"

  ranges

-- applies the ranges from the last one, so that the positions of the ones
-- before it stay valid
apply = (buffer, ranges) ->
  buffer\as_one_undo ->
    for j = #ranges, 1, -1
      {:start, :stop, :text} = ranges[j]
      buffer\delete start, stop - 1 if stop > start
      buffer\insert text, start if #text > 0

-- applies edits, a list of TextEdits, to buffer as one undo step. Returns
-- true, or nil and an error, leaving buffer untouched.
apply_text_edits = (buffer, edits) ->
  return nil, "'#{buffer.title}' is read-only" if buffer.read_only
  ranges, err = resolve buffer, edits
  return nil, err unless ranges
  apply buffer, ranges
  true

-- returns a list of the documents changed by edit, as {:uri, :version, :edits}
documents_of = (edit) ->
  docs = {}
  if edit.documentChanges
    for change in *edit.documentChanges
      -- resource operations aren't advertised, so they shouldn't be here
      return nil, "unsupported operation '#{change.kind}'" if change.kind
      { uri: doc_uri, :version } = change.textDocument
      append docs, { uri: doc_uri, :version, edits: change.edits }
  elseif edit.changes
    for doc_uri, edits in pairs edit.changes
      append docs, { uri: doc_uri, :edits }

  docs

buffer_for = (file) ->
  for b in *app.buffers
    return b if b.file == file
  nil

-- loads file into a buffer that isn't shown
load_hidden = (file) ->
  buffer = app\new_buffer mode.for_file(file)
  status, err = pcall -> buffer.file = file
  unless status
    app\close_buffer buffer, true
    return nil, err

  signal.emit 'file-opened', :file, :buffer
  buffer

-- returns why the server's edits for version of buffer can't be applied, if
-- they're not for the text it has
stale_reason = (buffer, version) ->
  state = buffer.data.lsp
  if state
    if state.dirty or (version != nil and version != state.version)
      return "'#{buffer.title}' has changed since the server's edit was made"
  elseif buffer.modified
    -- the server only knows the file
    return "'#{buffer.title}' has unsaved changes the server hasn't seen"

  nil

-- applies edit, a WorkspaceEdit with text edits only, to the buffers of its
-- files. Files that aren't open are loaded into buffers that aren't shown, and
-- left unsaved. Nothing is changed unless all of it can be applied, and each
-- buffer's part is one undo step. Returns a table with the changed `buffers`
-- and those of them that were `opened`, or nil and an error.
apply_workspace_edit = (edit) ->
  docs, err = documents_of edit
  return nil, err unless docs

  opened = {}
  fail = (reason) ->
    app\close_buffer b, true for b in *opened
    nil, reason

  seen = {}
  for doc in *docs
    continue if #doc.edits == 0
    path = uri.to_path doc.uri
    return fail "unsupported uri '#{doc.uri}'" unless path
    file = File path
    buffer = buffer_for file
    unless buffer
      return fail "'#{file}' does not exist" unless file.exists
      buffer, err = load_hidden file
      return fail "failed to open '#{file}': #{err}" unless buffer
      append opened, buffer

    -- later edits of a document would be for its text after the earlier ones
    return fail "several edits of '#{buffer.title}'" if seen[buffer]
    seen[buffer] = true
    return fail "'#{buffer.title}' is read-only" if buffer.read_only
    reason = stale_reason buffer, doc.version
    return fail reason if reason
    doc.buffer = buffer
    doc.ranges, err = resolve buffer, doc.edits
    return fail err unless doc.ranges

  buffers = {}
  for doc in *docs
    continue unless doc.buffer
    apply doc.buffer, doc.ranges
    append buffers, doc.buffer

  -- the server is told about the result right away
  for buffer in *buffers
    lsp.attach buffer
    lsp.sync buffer

  { :buffers, :opened }

-- handles the workspace/applyEdit request
on_apply_edit = (params) ->
  result, err = apply_workspace_edit params.edit
  return { applied: true } if result

  what = params.label and "'#{params.label}'" or "the server's edit"
  log.warn "LSP: could not apply #{what}: #{err}"
  { applied: false, failureReason: err }

:apply_text_edits, :apply_workspace_edit, :on_apply_edit
