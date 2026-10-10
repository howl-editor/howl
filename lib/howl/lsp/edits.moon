-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

lsp = require 'howl.lsp'
uri = require 'howl.lsp.uri'
{:app, :Buffer} = howl
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

-- returns a list of the documents changed by edit, a WorkspaceEdit, as
-- {:uri, :version, :edits}, or nil and an error
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

-- returns a buffer of its own with the text of file, which isn't open, for
-- applying edits to it. Returns nil and an error if file can't be edited.
read_file = (file) ->
  return nil, "'#{file}' does not exist" unless file.exists
  return nil, "'#{file}' is not writeable" unless file.writeable
  status, contents = pcall -> file.contents
  return nil, "failed to read '#{file}': #{contents}" unless status
  -- the buffer would clean up invalid text, changing more than the edits do
  return nil, "'#{file}' is not valid UTF-8" unless contents.is_valid_utf8
  buffer = Buffer {}
  buffer.collect_revisions = false
  buffer.title = file.basename
  buffer.text = contents
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

-- applies edit, a WorkspaceEdit with text edits only, to its files. Files that
-- aren't open are written without opening them. Open buffers are edited with
-- each one's part as one undo step, and then saved unless they had other
-- unsaved changes. Nothing is changed unless all of it
-- can be applied, short of a file failing to be written. Returns a table with
-- the edited open `buffers`, the ones of them `saved` and the `written` files,
-- or nil and an error.
apply_workspace_edit = (edit) ->
  docs, err = documents_of edit
  return nil, err unless docs

  seen = {}
  for doc in *docs
    continue if #doc.edits == 0
    path = uri.to_path doc.uri
    return nil, "unsupported uri '#{doc.uri}'" unless path
    file = File path
    -- later edits of a document would be for its text after the earlier ones
    return nil, "several edits of '#{file.basename}'" if seen[file.path]
    seen[file.path] = true

    buffer = buffer_for file
    if buffer
      return nil, "'#{buffer.title}' is read-only" if buffer.read_only
      reason = stale_reason buffer, doc.version
      return nil, reason if reason
      doc.save = not buffer.modified and file.writeable
    else
      buffer, err = read_file file
      return nil, err unless buffer
      doc.file = file

    doc.buffer = buffer
    doc.ranges, err = resolve buffer, doc.edits
    return nil, err unless doc.ranges

  -- files are written first, as that's what can fail
  written = {}
  for doc in *docs
    continue unless doc.file
    apply doc.buffer, doc.ranges
    status, err = pcall -> doc.file.contents = doc.buffer.text
    return nil, "failed to write '#{doc.file}': #{err}" unless status
    append written, doc.file

  buffers, saved = {}, {}
  for doc in *docs
    continue if doc.file or not doc.buffer
    {:buffer} = doc
    apply buffer, doc.ranges
    append buffers, buffer
    -- the server is told about the result right away
    lsp.sync buffer
    if doc.save
      status, err = pcall -> buffer\save!
      if status
        append saved, buffer
      else
        log.error "Failed to save '#{buffer.title}': #{err}"

  { :buffers, :saved, :written }

-- handles the workspace/applyEdit request
on_apply_edit = (params) ->
  result, err = apply_workspace_edit params.edit
  return { applied: true } if result

  what = params.label and "'#{params.label}'" or "the server's edit"
  log.warn "LSP: could not apply #{what}: #{err}"
  { applied: false, failureReason: err }

:apply_text_edits, :apply_workspace_edit, :documents_of, :on_apply_edit
