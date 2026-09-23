-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Client = require 'howl.lsp.client'
uri = require 'howl.lsp.uri'
{:config, :signal, :sys, :timer, :Project} = howl

-- don't restart a server that exited less than this many seconds ago
RESTART_THROTTLE = 30

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
  state.client\notify 'textDocument/didClose', textDocument: { uri: state.uri }

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
    dirty: false
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
  state.dirty = false
  state.version += 1
  state.client\notify 'textDocument/didChange', {
    textDocument: { uri: state.uri, version: state.version },
    contentChanges: { { text: buffer.text } }
  }

-- converts a buffer position to a LSP position, using the utf-8 encoding
position = (buffer, pos) ->
  line = buffer.lines\at_pos pos
  {
    line: line.nr - 1,
    character: buffer\byte_offset(pos) - line.byte_start_pos
  }

signal.connect 'file-opened', (args) -> attach args.buffer

signal.connect 'buffer-mode-set', (args) ->
  -- this is also signaled during buffer construction
  return unless args.buffer.data
  detach args.buffer
  attach args.buffer

signal.connect 'buffer-closed', (args) -> detach args.buffer

signal.connect 'buffer-modified', (args) ->
  buffer = args.buffer
  state = buffer.data.lsp
  return unless state
  state.dirty = true
  unless state.sync_timer
    state.sync_timer = timer.on_idle 1, ->
      state.sync_timer = nil
      sync buffer if buffer.data.lsp == state

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
  clients: -> [c for _, c in pairs clients]
}
