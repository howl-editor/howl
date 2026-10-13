-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Client = require 'howl.lsp.client'
uri = require 'howl.lsp.uri'
diagnostics = require 'howl.lsp.diagnostics'
inspect = require 'howl.inspect'
serpent = require 'serpent'
{:config, :dispatch, :signal, :sys, :timer, :Project} = howl

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
warned = {}
-- the registered servers, in order of preference
servers = {}
-- the ids of servers that failed to initialize, which aren't started again
failed = {}
local idle_check, refresh

config.define
  name: 'lsp_enabled'
  description: 'Whether language servers (LSP) are used'
  type_of: 'boolean'
  default: true

config.define
  name: 'lsp_server'
  description: 'The language server (LSP) for a buffer: the name of a registered server, or a server definition'
  validate: (value) ->
    type(value) == 'string' or type(value) == 'table' and type(value.name) == 'string'
  tostring: (value) ->
    type(value) == 'table' and serpent.line(value, comment: false) or tostring value

config.define
  name: 'lsp_server_idle_stop'
  description: 'Minutes a language server may go unused before it is stopped (0 = never)'
  type_of: 'positive_number'
  scope: 'global'
  default: 30

executable_of = (command) -> command\match '^%s*(%S+)'

warn_once = (msg) ->
  return if warned[msg]
  log.warn msg
  warned[msg] = true

-- returns a server definition with server's fields, and those it leaves out
-- taken from base. Its `id` is the same for definitions with the same name,
-- command and init options.
resolve = (server, base = {}) ->
  options = server.init_options or base.init_options
  def = {
    name: server.name,
    command: server.command or base.command,
    init_options: options
  }
  def.id = "#{def.name}: #{def.command}"
  def.id ..= " #{serpent.line options, comment: false}" if options
  def

-- returns the variables of project's environment if they're known. Otherwise
-- they're found in the background, and the showing buffers are attached once
-- they are.
environment_of = (project) ->
  unless project.environment
    waiting = false
    dispatch.launch ->
      project\find_environment!
      refresh! if waiting
    waiting = true

  project.environment

serves = (server, mode_name) ->
  for name in *server.modes
    return true if name == mode_name
  false

-- returns the definition of the server to start for buffer, if any. A
-- configured `lsp_server` names a registered server, or is a definition filled
-- in from the registered server of the same name. Without it, it's the first
-- server registered for the buffer's mode that the project's processes find,
-- once the project's environment is known.
server_for = (buffer) ->
  return nil unless buffer.config.lsp_enabled
  configured = buffer.config.lsp_server
  configured = name: configured if type(configured) == 'string'

  if configured and not configured.name.is_blank
    registered = [s for s in *servers when s.name == configured.name]
    server = resolve configured, registered[1]
    unless server.command
      warn_once "LSP: no language server named '#{server.name}' is registered"
      return nil
    return not failed[server.id] and server or nil

  return nil unless buffer.file
  candidates = [s for s in *servers when serves(s, buffer.mode.name)]
  return nil if #candidates == 0
  project = Project.for_file buffer.file
  return nil unless project and environment_of project

  for server in *candidates
    server = resolve server
    return server if not failed[server.id] and project\find_executable executable_of(server.command)
  nil

-- registers a language server: `name`, `command`, `modes` (the name of a mode
-- it serves, or a list of them) and optionally `init_options`. The servers for
-- a mode are preferred in the order they're registered, and registering a name
-- again replaces that server in its place.
register_server = (server) ->
  for field in *{ 'name', 'command', 'modes' }
    error "Missing field `#{field}` for language server", 2 unless server[field]

  server = { k, v for k, v in pairs server }
  server.modes = { server.modes } if type(server.modes) == 'string'
  replaced = false
  for i, s in ipairs servers
    if s.name == server.name
      servers[i] = server
      replaced = true
      break

  table.insert servers, server unless replaced
  refresh!

unregister_server = (name) ->
  servers = [s for s in *servers when s.name != name]
  refresh!

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
    failed[client.server_id] = true
  elseif not client.stopping
    exited_at[client.key] = sys.time!

  for buffer in *howl.app.buffers
    state = buffer.data.lsp
    if state and state.client == client
      detach buffer
      buffer.data.lsp_reattach = true

  refresh! if client.restarting

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
  server = server_for buffer
  return nil unless server

  -- servers are only started for files within a project
  project = Project.for_file file
  return nil unless project
  root = project.root
  key = "#{server.id}@#{root.path}"
  client = clients[key]
  return client if client

  last_exit = exited_at[key]
  return nil if last_exit and sys.time! - last_exit < RESTART_THROTTLE

  return nil unless environment_of project

  -- only explicitly configured servers can be missing here
  executable = executable_of server.command
  unless project\find_executable executable
    warn_once "LSP: '#{executable}' not found for #{root}, language server not started"
    return nil

  client = Client {
    name: server.name,
    cmd: server.command,
    init_options: server.init_options,
    :root,
    env: project\process_env!,
    :on_exit,
    on_initialized: on_initialized
  }
  client.notification_handlers['textDocument/publishDiagnostics'] = (params) ->
    on_diagnostics client, params
  client.request_handlers['workspace/applyEdit'] = (params) ->
    require('howl.lsp.edits').on_apply_edit params
  client.key = key
  client.server_id = server.id
  client.completion_triggers = {}
  clients[key] = client
  schedule_idle_check!
  client\start!
  log.info "LSP: started '#{server.name}' for #{root}"
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

-- converts a LSP position to a buffer position. A character beyond the end of
-- its line means the end of the line, and a line beyond the last one the end
-- of the buffer.
pos_for = (buffer, lsp_pos) ->
  line = buffer.lines[lsp_pos.line + 1]
  return buffer.length + 1 unless line
  buffer\char_offset line.byte_start_pos + math.min(lsp_pos.character, line.size)

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
-- now use, if any. Hidden buffers attach once they're shown. Servers left
-- without buffers this way are stopped.
refresh = ->
  app = rawget howl, 'app'
  return unless app
  left = {}
  for buffer in *app.buffers
    state = buffer.data.lsp
    server = server_for buffer
    if state and (not server or state.client.server_id != server.id)
      left[state.client] = true
      detach buffer
      state = nil
    attach buffer if server and not state and buffer.showing

  for buffer in *app.buffers
    left[buffer.data.lsp.client] = nil if buffer.data.lsp
  client\stop! for client in pairs left

config.watch 'lsp_enabled', refresh
config.watch 'lsp_server', refresh

-- buffers attach when shown rather than when opened, since the restored session
-- opens buffers that may never be visited. Previews don't signal this.
signal.connect 'after-buffer-switch', (args) -> attach args.current_buffer

signal.connect 'buffer-mode-set', (args) ->
  -- this is also signaled during buffer construction
  return unless args.buffer.data
  detach args.buffer
  attach args.buffer if args.buffer.showing

signal.connect 'buffer-closed', (args) -> detach args.buffer

-- the project's servers are restarted with the new environment once they exit
signal.connect 'project-environment-changed', (args) ->
  root = args.project.root
  for client in *[c for _, c in pairs clients when c.root == root]
    client.restarting = true
    client\stop!

signal.connect 'text-inserted', (args) -> record_change 'inserted', args
signal.connect 'text-deleted', (args) -> record_change 'deleted', args
signal.connect 'text-changed', (args) -> record_change 'changed', args

signal.connect 'buffer-saved', (args) ->
  buffer = args.buffer
  state = buffer.data.lsp
  if state and state.uri != uri.for_file(buffer.file)
    detach buffer
    state = nil

  state or= attach buffer if buffer.showing
  return unless state
  sync buffer
  state.client\notify 'textDocument/didSave', textDocument: { uri: state.uri }

{
  :attach
  :detach
  :client_for
  :server_for
  :register_server
  :unregister_server
  :on_exit
  :stop_idle
  :sync
  :position
  :pos_for
  :on_diagnostics
  :refresh
  clients: -> [c for _, c in pairs clients]
  _clients: clients
}
