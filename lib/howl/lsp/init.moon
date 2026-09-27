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

-- how often, in seconds, to look for idle servers
IDLE_CHECK_INTERVAL = 60

clients = {}
exited_at = {}
executables = {}
warned = {}
-- commands that failed to initialize, which aren't started again
failed = {}
local idle_check

config.define
  name: 'lsp_enabled'
  description: 'Whether language servers (LSP) are used'
  type_of: 'boolean'
  default: true

config.define
  name: 'lsp_command'
  description: 'The command used to start a language server (LSP) for a buffer,
overriding the servers known by the mode'
  type_of: 'string'

config.define
  name: 'lsp_server_idle_stop'
  description: 'Minutes a language server may go unused before it is stopped (0 = never)'
  type_of: 'positive_number'
  scope: 'global'
  default: 30

-- returns the path of cmd's executable, or nil if it's not installed
executable_for = (cmd) ->
  name = cmd\match '^%s*(%S+)'
  if executables[name] == nil
    executables[name] = sys.find_executable(name) or false
  executables[name] or nil, name

-- returns the command to start a server for buffer with, if any. Without a
-- configured `lsp_command` it's the first installed server from the mode's
-- `lsp_servers`.
command_for = (buffer) ->
  return nil unless buffer.config.lsp_enabled
  cmd = buffer.config.lsp_command
  unless cmd == nil or cmd.is_blank
    return not failed[cmd] and cmd or nil

  servers = buffer.mode and buffer.mode.lsp_servers
  return nil unless servers
  for server in *servers
    return server if not failed[server] and executable_for server
  nil

-- servers are only started for files within a project
root_for = (file) ->
  project = Project.for_file file
  project and project.root

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

-- buffers are attached again on their next edit, possibly to another server
on_exit = (client) ->
  clients[client.key] = nil if clients[client.key] == client
  if client.failure
    failed[client.cmd] = true
  elseif not client.stopping
    exited_at[client.key] = sys.time!

  for buffer in *howl.app.buffers
    state = buffer.data.lsp
    if state and state.client == client
      detach buffer
      buffer.data.lsp_reattach = true

-- stops the servers that haven't been used for `lsp_server_idle_stop` minutes
stop_idle = (now = sys.time!) ->
  limit = config.lsp_server_idle_stop * 60
  return if limit <= 0
  for _, client in pairs clients
    client\stop! if now - client.last_used >= limit

schedule_idle_check = ->
  return if idle_check
  idle_check = timer.after IDLE_CHECK_INTERVAL, ->
    idle_check = nil
    stop_idle!
    schedule_idle_check! if next clients

client_for = (buffer) ->
  state = buffer.data.lsp
  return state.client if state

  file = buffer.file
  return nil unless file
  cmd = command_for buffer
  return nil unless cmd

  root = root_for file
  return nil unless root
  key = "#{cmd}@#{root.path}"
  client = clients[key]
  return client if client

  last_exit = exited_at[key]
  return nil if last_exit and sys.time! - last_exit < RESTART_THROTTLE

  -- only explicitly configured commands can be missing here
  found, executable = executable_for cmd
  unless found
    unless warned[executable]
      log.warn "LSP: '#{executable}' not found, language server not started"
      warned[executable] = true
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
  schedule_idle_check!
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
  buffer.data.lsp_reattach = nil
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
  unless state
    -- the opened document includes this change
    if buffer.data.lsp_reattach
      buffer.data.lsp_reattach = nil
      attach buffer
    return

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

-- attaches or detaches the open buffers according to the server they should
-- now use, if any
refresh = ->
  app = rawget howl, 'app'
  return unless app
  for buffer in *app.buffers
    state = buffer.data.lsp
    cmd = command_for buffer
    if state and state.client.cmd != cmd
      detach buffer
      state = nil
    attach buffer if cmd and not state

config.watch 'lsp_enabled', refresh
config.watch 'lsp_command', refresh

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
  :command_for
  :on_exit
  :stop_idle
  :sync
  :position
  :on_diagnostics
  :refresh
  clients: -> [c for _, c in pairs clients]
  _clients: clients
}
