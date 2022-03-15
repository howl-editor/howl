-- json = require 'lunajson'
util = bundle_load 'util'
{:dispatch, :timer, :log} = howl

HANDLERS = {
  'window/logMessage': (msg) ->
    moon.p msg
    f = { 'error', 'warning', 'info', 'info' }
    output = f[msg.type] or 'info'
    log[output] msg.message
}

class LanguageServer
  new: (@process, @working_directory) =>
    @initialized = false
    @id = 1
    @stdout_buf = ''
    @operations = {}
    -- @stdout_buf = ''

  run: =>
    timer.asap -> @_initialize!

    on_stdout = (s) ->
      messages, @stdout_buf = util.decode @stdout_buf .. s
      for msg in *messages
        moon.p msg
        if msg.id
          handle = @operations[msg.id]
          if msg.result
            dispatch.resume handle, msg.result
          elseif msg.error
            print "resume_with_error"
            dispatch.resume_with_error handle, msg.error.message
        else
          handler = HANDLERS[msg.method]
          if handler
            handler msg.params
          else
            print "! Unhandled message: #{msg.method}"

    on_stderr = (s) ->
      print "! <- #{s}"

    @process\pump on_stdout, on_stderr

  send: (message, params) =>
    req = util.rpc_request message, params, @id
    enc = util.encode(req)
    print "-> #{enc}"
    @process.stdin\write(enc)
    handle = dispatch.park "lsp-#{@process.pid}:#{message}"
    @operations[@id] = handle
    @id += 1
    dispatch.wait handle

  _initialize: =>
    print 'initialize'
    dispatch.launch ->
      res = @send 'initialize', {
        processId: nil,
        clientInfo: {
          name: 'Howl Editor',
          version: 'ultimate'
        },
        locale: 'en-US',
        capabilities: {
          textDocument: {
            definition: {

            }
          }
        },
        rootUri: "file://#{@working_directory}"
      }, 1
      print "_on_initialized"
      moon.p res
      @capabilities = res.capabilities

      res = @send 'textDocument/didOpen', {
        textDocument: {
          uri: "file:///home/nilnor/code/playad/resources-js/src/index.js"
          -- uri: "file://src/index.js"
        }
      }
      moon.p res

      res = @send 'textDocument/definition', {
        textDocument: {
          uri: "file:///home/nilnor/code/playad/resources-js/src/index.js"
          -- uri: "file://src/index.js"
        }
        position: {
          line: 2,
          character: 8
        }
      }

      -- res = @send 'textDocument/definition', {
      --   textDocument: {
      --     uri: "file:///home/nilnor/code/playad/adten-configuration/lib/adten.rb"
      --   }
      --   position: {
      --     line: 23,
      --     character: 15
      --   }
      -- }
      print 'def return'
      moon.p res

    print 'initialize return'


  -- _on_initialized: (response) =>
  --   print "_on_initialized"
  --   @capabilities = response.capabilities

    -- @send 'textDocument/definition', {
    --   textDocument: {
    --     uri: "file:///home/nilnor/code/playad/adten-configuration/lib/adten.rb"
    --   }
    --   position: {
    --     line: 23,
    --     character: 15
    --   }
    -- }

    -- @send 'textDocument/definition', {
    --   textDocument: {
    --     uri: "file:///home/nilnor/code/playad/resources-js/src/index.js"
    --   }
    --   position: {
    --     line: 2,
    --     character: 8
    --   }
    -- }

{
  for_process: (process, working_directory) ->
    LanguageServer process, working_directory

  for_command: (cmd, working_directory) ->
    process = howl.io.Process({
      :cmd,
      working_directory: working_directory,
      read_stdout: true,
      read_stderr: true,
      write_stdin: true,
    })
    LanguageServer process, working_directory

  -- :encode
  -- :decode
}


