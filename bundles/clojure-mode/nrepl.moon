bencode = bundle_load 'bencode.lua'
has_luasocket, socket = pcall require, 'socket'

import PropertyTable from howl.aux

local conn, host, port

open = -> conn != nil

connect = (port, host = 'localhost') ->
  error "Missing argument #1 (port)" unless port
  error "nrepl needs `luasocket` installed to function" unless has_luasocket
  conn = assert socket.tcp!
  assert conn\connect host, port
  conn\settimeout 0.05

send = (cmd) ->
  error "nrepl: not connected" unless open!

  payload = bencode.encode(cmd)
  assert conn\send payload
  for i = 1,5
    res = { conn\receive! }
    error = res[1]
    return bencode.decode error if error
    answer = res[3]
    return bencode.decode answer if not answer.empty

  error "Timeout waiting for reply from nrepl"

eval = (form) ->
  send op: 'eval', code: form

ns_expression = (namespace) ->
  return "" unless namespace
  "(if (find-ns '#{namespace}) '#{namespace} 'clojure.core)"

complete = (prefix, namespace) ->
  payload = "(do (use 'complete.core)(completions \"#{prefix}\" #{ns_expression namespace}))"
  res = eval payload
  if res.value
    [alt for alt in res.value\gmatch '"([^"]+)"']
  else
    {}

close = ->
  if open!
    send op: 'close'
    conn\close!
    conn = nil

PropertyTable {
  :connect,
  :send,
  :eval,
  :complete,
  :close,

  is_connected: get: -> open!
}
