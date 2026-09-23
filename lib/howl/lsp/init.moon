-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Client = require 'howl.lsp.client'
uri = require 'howl.lsp.uri'
diagnostics = require 'howl.lsp.diagnostics'
inspect = require 'howl.inspect'
{:config, :signal, :sys, :timer, :Project} = howl

-- don't restart a server that exited less than this many seconds ago
RESTART_THROTTLE = 30

-- beyond this many pending changes the full text is sent instead
MAX_CHANGES = 100

-- TextDocumentSyncKind.Incremental
INCREMENTAL = 2

clients = {}
exited_at = {}
missing_executables = {}

config.define
  name: 'lsp_command'
  description: 'The command used to start a language server (LSP) for a buffer'
  type_of: 'string'

root_for = (file) ->
  project = Project.for_file file
  project and project.root or file.parent

-- a buffer's `completion_triggers` is shared with its client, and filled in
-- once the server has told us its trigger characters
on_initialized = (client) ->
  provider = client.capabilities.completionProvider
  if provider and provider.triggerCharacters
    for c in *provider.triggerCharacters
      client.completion_triggers[c] = true

detach = (buffer) ->
  state = buffer.data.lsp
  return unless state
  buffer.data.lsp = nil
  buffer.completion_triggers = nil if buffer.completion_triggers == state.client.completion_triggers
  timer.cancel state.sync_timer if state.sync_timer
  inspect.publish buffer, 'lsp', {}
  state.client\notify 'textDocument/didClose', textDocument: { uri: state.uri }

on_diagnostics = (client, params) ->
  for buffer in *howl.app.buffers
    state = buffer.data.lsp
    if state and state.client == client and state.uri == params.uri
      -- skip diagnostics for text that has since changed
      return if state.dirty
      return if params.version and params.version != state.version
      inspect.publish buffer, 'lsp', diagnostics.to_items(params.diagnostics)
      return

on_exit = (client) ->
  clients[client.key] = nil if clients[client.key] == client
  exited_at[client.key] = sys.time!
  for buffer in *howl.app.buffers
    state = buffer.data.lsp
    detach buffer if state and state.client == client

client_for = (buffer) ->
  state = buffer.data.lsp
  return state.client if state

  cmd = buffer.config.lsp_command
  file = buffer.file
  return nil unless cmd and not cmd.is_blank and file

  root = root_for file
  key = "#{cmd}@#{root.path}"
  client = clients[key]
  return client if client

  last_exit = exited_at[key]
  return nil if last_exit and sys.time! - last_exit < RESTART_THROTTLE

  executable = cmd\match '^%s*(%S+)'
  unless sys.find_executable executable
    unless missing_executables[executable]
      log.warn "LSP: '#{executable}' not found, language server not started"
      missing_executables[executable] = true
    return nil

  client = Client {
    :cmd,
    :root,
    :on_exit,
    on_initialized: on_initialized
  }
  client.notification_handlers['textDocument/publishDiagnostics'] = (params) ->
    on_diagnostics client, params
  client.key = key
  client.completion_triggers = {}
  clients[key] = client
  client\start!
  log.info "LSP: started '#{cmd}' for #{root}"
  client

attach = (buffer) ->
  return buffer.data.lsp if buffer.data.lsp
  client = client_for buffer
  return nil unless client

  state = {
    :client,
    uri: uri.for_file(buffer.file),
    version: 1,
    dirty: false,
    changes: {},
    full: false
  }
  buffer.data.lsp = state
  buffer.completion_triggers = client.completion_triggers
  client\notify 'textDocument/didOpen', textDocument: {
    uri: state.uri,
    languageId: buffer.mode.name,
    version: state.version,
    text: buffer.text
  }
  state

-- sends any pending changes for buffer to the server
sync = (buffer) ->
  state = buffer.data.lsp
  return unless state and state.dirty
  changes = state.full and { { text: buffer.text } } or state.changes
  state.dirty = false
  state.full = false
  state.changes = {}
  state.version += 1
  state.client\notify 'textDocument/didChange', {
    textDocument: { uri: state.uri, version: state.version },
    contentChanges: changes
  }

-- converts a buffer position to a LSP position, using the utf-8 encoding
position = (buffer, pos) ->
  line = buffer.lines\at_pos pos
  {
    line: line.nr - 1,
    character: buffer\byte_offset(pos) - line.byte_start_pos
  }

sync_kind = (client) ->
  kind = client.capabilities and client.capabilities.textDocumentSync
  kind = kind.change if type(kind) == 'table'
  kind or 0

-- returns the position reached by moving past text from start
end_of = (start, text) ->
  breaks, after = 0, nil
  pos = text\find '[\r\n]'
  while pos
    pos += 1 if text\byte(pos) == 13 and text\byte(pos + 1) == 10
    breaks += 1
    after = pos + 1
    pos = text\find '[\r\n]', after

  if breaks == 0
    { line: start.line, character: start.character + #text }
  else
    { line: start.line + breaks, character: #text - after + 1 }

-- an edit that joins or splits a "\r\n" pair changes the line numbering
-- around it in a way a range can't express
splits_crlf = (buffer, at_pos, removed, inserted) ->
  if at_pos > 1 and buffer\sub(at_pos - 1, at_pos - 1) == '\r'
    return true if removed\byte(1) == 10 or inserted\byte(1) == 10

  if removed\byte(-1) == 13 or inserted\byte(-1) == 13
    next_pos = at_pos + inserted.ulen
    return true if buffer\sub(next_pos, next_pos) == '\n'

  false

record_change = (what, args) ->
  buffer = args.buffer
  state = buffer.data.lsp
  return unless state
  state.dirty = true
  unless state.sync_timer
    state.sync_timer = timer.on_idle 1, ->
      state.sync_timer = nil
      sync buffer if buffer.data.lsp == state

  return if state.full
  removed, inserted = switch what
    when 'inserted' then '', args.text
    when 'deleted' then args.text, ''
    else args.prev_text, args.text

  if sync_kind(state.client) != INCREMENTAL or
      #state.changes >= MAX_CHANGES or
      splits_crlf(buffer, args.at_pos, removed, inserted)
    state.full = true
    state.changes = {}
    return

  start = position buffer, args.at_pos
  table.insert state.changes, {
    range: { :start, ['end']: end_of(start, removed) },
    text: inserted
  }

signal.connect 'file-opened', (args) -> attach args.buffer

signal.connect 'buffer-mode-set', (args) ->
  -- this is also signaled during buffer construction
  return unless args.buffer.data
  detach args.buffer
  attach args.buffer

signal.connect 'buffer-closed', (args) -> detach args.buffer

signal.connect 'text-inserted', (args) -> record_change 'inserted', args
signal.connect 'text-deleted', (args) -> record_change 'deleted', args
signal.connect 'text-changed', (args) -> record_change 'changed', args

signal.connect 'buffer-saved', (args) ->
  buffer = args.buffer
  state = buffer.data.lsp
  if state and state.uri != uri.for_file(buffer.file)
    detach buffer
    state = nil

  state or= attach buffer
  return unless state
  sync buffer
  state.client\notify 'textDocument/didSave', textDocument: { uri: state.uri }

signal.connect 'app-ready', ->
  attach b for b in *howl.app.buffers

{
  :attach
  :detach
  :client_for
  :sync
  :position
  :on_diagnostics
  clients: -> [c for _, c in pairs clients]
}
