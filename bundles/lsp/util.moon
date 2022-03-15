json = require 'lunajson'
append = table.insert

encode = (message) ->
  json_message = json.encode(message)
  "Content-Length:#{#json_message}\r\n\r\n#{json_message}"

parse_header = (h) ->
  name, val = h\match '([^:]+):(.+)'
  name\lower!\gsub('-', '_'), val

decode_one = (s) ->
  s_headers, payload_p = s\umatch(r"^(?:([\\w-]+:[^\\r]+)\r\n)+\r\n()")
  -- print '-- decode_one ---'
  -- moon.p s
  unless s_headers
    return nil, ''

  -- print s_headers
  -- print payload_p

  headers = {parse_header(h) for h in s_headers\gmatch("[^\r]+")}
  return nil unless headers.content_length
  payload_length = tonumber(headers.content_length)
  -- moon.p payload_length
  payload = s\sub(payload_p, payload_p + payload_length - 1)
  -- print payload
  -- print "payload_length: #{payload_length}, actual: #{#payload}"
  unless payload_length == #payload
    -- print "payload size #{#payload} not matching header #{payload_length}"
    return nil, s

  json.decode(payload), s\sub(payload_p + payload_length)

decode = (s) ->
  messages = {}
  msg, rest = decode_one(s)
  while msg
    append messages, msg
    msg, rest = decode_one(rest)

  messages, rest

rpc_request = (method, params, id = nil) ->
  {
    jsonrpc: "2.0",
    method: method,
    :params,
    :id
  }

{:encode, :decode_one, :decode, :rpc_request}
