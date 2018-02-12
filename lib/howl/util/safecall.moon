-- Copyright 2012-2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- safecall is a utility function similar to pcall. However, upon an error, it
-- logs it via log.critical using the given message and the full error traceback.

import critical from howl.log

return (errmsg, fn, args) ->
  local tb
  onerror = (msg) ->
    tb = debug.traceback!
    msg
  status, ret = xpcall fn, onerror, args
  if not status
    if errmsg
      critical "#{errmsg}: #{ret}"
    else
      critical ret
    _G.print "full error traceback: #{tb}"
  status, ret
