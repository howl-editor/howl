-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
json_rpc = require 'howl.json_rpc'
uri = require 'howl.lsp.uri'
{:dispatch, :timer, :sys} = howl
{:Process} = howl.io
append = table.insert

REQUEST_TIMEOUT = 10
MAX_STDERR_LINES = 20

-- set HOWL_LSP_TRACE=1 to print all LSP traffic to stdout
trace = sys.env.HOWL_LSP_TRACE and (dir, data) -> print "LSP #{dir} #{data}"

client_capabilities = -> {
  general: {
    positionEncodings: { 'utf-8' }
  }
  textDocument: {
    synchronization: {
      didSave: true
    }
    completion: {
      completionItem: {
        snippetSupport: false
      }
      contextSupport: true
    }
    publishDiagnostics: {
      versionSupport: true
    }
  }
  workspace: {
    workspaceFolders: true
  }
}

class Client
  -- opts: `cmd`, `root` (a File), and optionally `process` (used instead of
  -- spawning `cmd`), `on_initialized` and `on_exit` (called with the client
  -- once the server is initialized, and when it exits) and
  -- `notification_handlers` (a table of method -> handler(params))
  new: (opts) =>
    @cmd = opts.cmd
    @root = opts.root
    @on_initialized = opts.on_initialized
    @on_exit = opts.on_exit
    @notification_handlers = opts.notification_handlers or {}
    @initialized = false
    @dead = false
    @capabilities = {}
    @stderr = {}

    @_pending = {}
    @_next_id = 0
    @_deferred = {}
    @_queue = {}
    @_writing = false
    @_decoder = json_rpc.Decoder!

    @process = opts.process or Process {
      cmd: @cmd,
      working_directory: @root,
      read_stdout: true,
      read_stderr: true,
      write_stdin: true
    }

    dispatch.launch -> @_read!

  -- sends the initialize handshake; messages sent before it completes are
  -- held back until it has
  start: =>
    root_uri = uri.for_file @root
    params = {
      processId: tonumber(ffi.C.getpid!),
      clientInfo: { name: 'Howl Editor' }
      rootUri: root_uri,
      workspaceFolders: { { uri: root_uri, name: @root.basename } }
      capabilities: client_capabilities!
    }

    @_send_request 'initialize', params, (result, err) ->
      if err
        @_fail "initialize failed: #{err}"
        return

      @capabilities = result.capabilities or {}
      @server_info = result.serverInfo
      encoding = @capabilities.positionEncoding
      unless encoding == 'utf-8'
        @_fail "server does not support the utf-8 position encoding (got #{encoding or 'utf-16'})"
        return

      @initialized = true
      @_write json_rpc.notification('initialized', {})
      deferred = @_deferred
      @_deferred = {}
      @_write msg for msg in *deferred
      @.on_initialized(@) if @on_initialized

  -- sends a request, calling `callback(result, err)` with the response. The
  -- callback is never invoked before this returns. Returns the request id,
  -- or nil and an error message if the request can't be sent.
  send_request: (method, params, callback, timeout = REQUEST_TIMEOUT) =>
    @_send_request method, params, callback, timeout

  -- sends a request and waits for the response, returning the result or nil
  -- and an error message. Must be called from a coroutine.
  request: (method, params, timeout) =>
    handle = dispatch.park "lsp-request-#{method}"
    id, err = @send_request method, params, ((result, r_err) -> dispatch.resume handle, result, r_err), timeout
    unless id
      dispatch.resume_or_clear handle
      return nil, err

    dispatch.wait handle

  notify: (method, params) =>
    return if @dead
    @_send json_rpc.notification(method, params or {})

  cancel: (id) =>
    entry = @_pending[id]
    return unless entry
    @_pending[id] = nil
    timer.cancel entry.timer
    @notify '$/cancelRequest', :id

  stop: =>
    return if @dead
    @send_request 'shutdown', nil, ->
      @notify 'exit'
    timer.after 2, ->
      @process\send_signal 'TERM' unless @process.exited

  _send_request: (method, params, callback, timeout = REQUEST_TIMEOUT) =>
    return nil, 'server is not running' if @dead
    @_next_id += 1
    id = @_next_id
    entry = :callback, :method
    entry.timer = timer.after timeout, ->
      if @_pending[id] == entry
        @_pending[id] = nil
        callback nil, "request '#{method}' timed out"

    @_pending[id] = entry
    @_send json_rpc.request(method, params, id)
    id

  _send: (msg) =>
    if @initialized or msg.method == 'initialize' or not msg.method
      @_write msg
    else
      append @_deferred, msg

  _write: (msg) =>
    data = json_rpc.encode msg
    trace '->', data if trace
    append @_queue, data
    return if @_writing
    @_writing = true
    dispatch.launch ->
      while #@_queue > 0 and not @dead
        chunk = table.concat @_queue
        @_queue = {}
        status, err = pcall @process.stdin.write, @process.stdin, chunk
        unless status
          log.error "LSP (#{@cmd}): failed to write to server: #{err}"
          break

      @_writing = false

  _read: =>
    status, err = pcall @process.pump, @process, @\_on_stdout, @\_on_stderr
    @_on_exited not status and err or nil

  _on_stdout: (data) =>
    return unless data
    trace '<-', data if trace
    status, messages = pcall @_decoder.feed, @_decoder, data
    unless status
      log.error "LSP (#{@cmd}): #{messages}"
      @_decoder = json_rpc.Decoder!
      return

    for msg in *messages
      status, err = pcall @_on_message, @, msg
      log.error "LSP (#{@cmd}): error handling message: #{err}" unless status

  _on_stderr: (data) =>
    return unless data
    for line in data\gmatch '[^\n]+'
      append @stderr, line
      table.remove @stderr, 1 if #@stderr > MAX_STDERR_LINES

  _on_message: (msg) =>
    if msg.method
      if msg.id != nil
        @_on_server_request msg
      else
        handler = @notification_handlers[msg.method]
        handler msg.params if handler
    elseif msg.id != nil
      entry = @_pending[msg.id]
      return unless entry
      @_pending[msg.id] = nil
      timer.cancel entry.timer
      if msg.error
        entry.callback nil, msg.error.message or 'unknown error'
      else
        entry.callback msg.result

  _on_server_request: (msg) =>
    result = switch msg.method
      when 'workspace/configuration'
        items = msg.params and msg.params.items or {}
        list = [json_rpc.null for _ in *items]
        #list > 0 and list or json_rpc.empty_array!
      when 'client/registerCapability', 'client/unregisterCapability', 'window/workDoneProgress/create'
        json_rpc.null

    if result
      @_write json_rpc.response(msg.id, result)
    else
      @_write json_rpc.error_response(msg.id, -32601, "Method not supported: #{msg.method}")

  _fail: (reason) =>
    log.warn "LSP (#{@cmd}): #{reason}"
    @_shut_down!
    @process\send_signal 'TERM' unless @process.exited

  _on_exited: (err) =>
    unless @dead
      msg = err or @process.exit_status_string or 'exited'
      log.warn "LSP (#{@cmd}): server exited (#{msg})"
      for i = math.max(1, #@stderr - 4), #@stderr
        log.warn "LSP (#{@cmd}): #{@stderr[i]}"

    @_shut_down!
    @.on_exit(@) if @on_exit

  _shut_down: =>
    return if @dead
    @dead = true
    @initialized = false
    pending = @_pending
    @_pending = {}
    @_deferred = {}
    for _, entry in pairs pending
      timer.cancel entry.timer
      entry.callback nil, 'server is not running'

Client
