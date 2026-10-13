-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- Highlights the occurrences of the symbol at the cursor once the cursor has
-- rested on it, as found by the server's `documentHighlight`. The highlights
-- stay while the cursor is on one of them, and are cleared when it leaves them
-- or the buffer changes.

lsp = require 'howl.lsp'
{:config, :signal, :timer} = howl
{:highlight} = howl.ui
append = table.insert

-- a character of a word, in any language. The mode's `word_pattern` isn't used
-- since it can leave out short names, such as Python's one-letter ones.
WORD_CHAR = r'^[\\pL\\pN_]$'

-- DocumentHighlightKind.Write; Text and Read are shown the same
WRITE = 3

MARKER = 'lsp_occurrence'

-- the request waiting for the cursor to rest or for the server's answer. There
-- is at most one, for where the cursor last moved.
local pending

config.define
  name: 'lsp_occurrences_highlighted'
  description: 'Whether the occurrences of the symbol at the cursor are highlighted, as found by the language server'
  type_of: 'boolean'
  default: true

config.define
  name: 'lsp_occurrences_highlight_delay'
  description: 'How long the cursor rests on a symbol before its occurrences are highlighted (ms)'
  type_of: 'positive_number'
  default: 1000

highlight.define_default 'occurrence_highlight',
  type: highlight.ROUNDED_RECTANGLE
  background: '#8a63d2'
  background_alpha: 0.4
  height: 'text'

highlight.define_default 'occurrence_highlight_write',
  type: highlight.ROUNDED_RECTANGLE
  background: '#d98c3a'
  background_alpha: 0.45
  height: 'text'

cancel = ->
  return unless pending
  timer.cancel pending.timer if pending.timer
  pending.client\cancel pending.id if pending.id
  pending = nil

clear = (buffer) ->
  return unless buffer.data.lsp_highlights
  buffer.data.lsp_highlights = nil
  buffer.markers\remove name: MARKER

-- whether the cursor at pos is upon a word, being within it or just after it.
-- Just before it, as at the end of indentation, the cursor is not.
on_word = (buffer, pos) ->
  pos > 1 and buffer\sub(pos - 1, pos - 1)\umatch(WORD_CHAR) != nil

-- whether the cursor at pos is upon one of buffer's highlights
on_highlight = (buffer, pos) ->
  for range in *(buffer.data.lsp_highlights or {})
    return true if pos > range[1] and pos <= range[2]
  false

-- shows the highlights for the symbol at pos, unless it occurs only there
show = (buffer, highlights, pos) ->
  markers, ranges = {}, {}
  for h in *highlights
    start_pos = lsp.pos_for buffer, h.range.start
    end_pos = lsp.pos_for buffer, h.range['end']
    continue unless end_pos > start_pos
    flair = h.kind == WRITE and 'occurrence_highlight_write' or 'occurrence_highlight'
    append markers, { name: MARKER, :flair, start_offset: start_pos, end_offset: end_pos }
    append ranges, { start_pos, end_pos }

  clear buffer
  return if #markers == 0
  return if #ranges == 1 and pos >= ranges[1][1] and pos <= ranges[1][2]
  buffer.markers\add markers
  buffer.data.lsp_highlights = ranges

-- requests the highlights for the symbol at pos, showing them when they arrive
-- unless the request has been cancelled by then
request = (buffer, pos) ->
  cancel!
  state = buffer.data.lsp
  return unless state
  client = state.client
  return if client.initialized and not client.capabilities.documentHighlightProvider
  return unless on_word buffer, pos

  lsp.sync buffer
  req = :buffer, :client
  params = {
    textDocument: { uri: state.uri },
    position: lsp.position(buffer, pos)
  }
  req.id = client\send_request 'textDocument/documentHighlight', params, (result, err) ->
    return unless pending == req
    pending = nil
    return if err or type(result) != 'table' or buffer.data.lsp != state
    show buffer, result, pos

  pending = req if req.id

-- requests the highlights at the editor's cursor once it has rested there
schedule = (editor) ->
  cancel!
  buffer = editor.buffer
  return unless buffer.data.lsp and buffer.config.lsp_occurrences_highlighted
  req = :editor, :buffer
  -- `timer.after` would round whole seconds to its coarse ticks
  req.timer = timer.after_exactly buffer.config.lsp_occurrences_highlight_delay / 1000, ->
    return unless pending == req
    pending = nil
    request buffer, editor.cursor.pos if editor.buffer == buffer

  pending = req

on_cursor_changed = (editor) ->
  buffer = editor.buffer
  return if on_highlight buffer, editor.cursor.pos
  clear buffer
  schedule editor

-- the cursor moves on most edits, but not all
on_buffer_modified = (buffer) ->
  cancel! if pending and pending.buffer == buffer
  clear buffer
  editor = howl.app.editor
  schedule editor if editor and editor.buffer == buffer

config.watch 'lsp_occurrences_highlighted', ->
  cancel!
  app = rawget howl, 'app'
  return unless app
  for buffer in *app.buffers
    clear buffer unless buffer.config.lsp_occurrences_highlighted

signal.connect 'cursor-changed', (args) -> on_cursor_changed args.editor
signal.connect 'buffer-modified', (args) -> on_buffer_modified args.buffer
signal.connect 'editor-released', (args) ->
  cancel! if pending and pending.editor == args.editor

{
  :request
  :cancel
  :clear
}
