json = require 'lunajson'

rpc_request = (method, params, id = nil) ->
  {
    jsonrpc: "2.0",
    method: method,
    :params,
    :id
  }

encode = (message) ->
  json_message = json.encode(message)
  "Content-Length:#{#json_message}\r\n\r\n#{json_message}"

parse_header = (h) ->
  name, val = h\match '([^:]+):(.+)'
  name\lower!\gsub('-', '_'), val

decode = (s) ->
  s_headers, payload = s\umatch(r"^(?:([\\w-]+:[^\\r]+)\r\n)+\r\n(.+)")
  unless s_headers and payload
    return nil

  print s_headers

  headers = {parse_header(h) for h in s_headers\gmatch("[^\r]+")}
  return nil unless headers.content_length
  payload_length = tonumber(headers.content_length)
  moon.p payload_length
  unless payload_length == #payload
    print "payload size #{#payload} not matching header #{payload_length}"
    return nil

  json.decode payload

class LSP
  new: (@process) =>
    @initialized = false

  run: =>
    @_initialize!

    on_stdout = (s) ->
      print "<- #{s}"
      msg = decode s
      moon.p msg
    on_stderr = (s) ->
      print "! <- #{s}"

    @process\pump on_stdout, on_stderr

  _write: (message, params, id) =>
    req = rpc_request message, params, id
    enc = encode(req)
    print "-> #{enc}"
    @process.stdin\write(enc)

  _initialize: =>
    @_write 'initialize', {
      processId: nil,
      clientInfo: {
        name: 'Howl Editor',
        version: '0.6'
      },
      -- rootPath: '/home/nilnor/code/playad/adten-configuration'
      rootUri: 'file:///home/nilnor/code/playad/adten-configuration'
    }, 1

{
  for_process: (process) ->
    LSP process

  :encode
  :decode
}


