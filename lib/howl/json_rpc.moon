-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

json = require 'lunajson'
append = table.insert

-- sentinel for encoding an explicit JSON null
null = setmetatable {}, __tostring: -> 'null'

-- an empty table encodes as an object, use this for an empty JSON array
empty_array = -> {[0]: 0}

encode = (message) ->
  payload = json.encode message, null
  "Content-Length: #{#payload}\r\n\r\n#{payload}"

parse_headers = (s) ->
  headers = {}
  for line in s\gmatch '[^\r\n]+'
    name, val = line\match '^([^:]+):%s*(.-)%s*$'
    headers[name\lower!] = val if name
  headers

-- Accumulates raw stream data and extracts complete messages from it,
-- regardless of how the data is split into chunks.
class Decoder
  new: =>
    @_buffer = ''

  feed: (data) =>
    @_buffer ..= data
    messages = {}

    while true
      header_end = @_buffer\find '\r\n\r\n', 1, true
      break unless header_end
      headers = parse_headers @_buffer\sub(1, header_end - 1)
      length = tonumber headers['content-length']
      error "Missing Content-Length in JSON RPC message header" unless length
      body_start = header_end + 4
      body_end = body_start + length - 1
      break if #@_buffer < body_end
      append messages, json.decode(@_buffer\sub(body_start, body_end))
      @_buffer = @_buffer\sub body_end + 1

    messages

{
  :null
  :empty_array
  :encode
  :Decoder

  request: (method, params, id = nil) ->
    {
      jsonrpc: "2.0",
      method: method,
      :params,
      :id
    }

  notification: (method, params) ->
    { jsonrpc: '2.0', :method, :params }

  response: (id, result = null) ->
    { jsonrpc: '2.0', :id, :result }

  error_response: (id, code, message) ->
    { jsonrpc: '2.0', :id, error: { :code, :message } }
}
