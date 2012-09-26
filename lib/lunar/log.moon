_G = _G
import append, table from _G
import config from lunar

config.define
  name: 'max_log_entries'
  description: 'Maximum number of log entries to keep in memory'
  default: 1000
  type_of: 'number'

log = {}
setfenv 1, log

export entries = {}

dispatch = (level, message) ->
  append entries, :message, :level
  if _G.window
    status = _G.window.status
    status[level] status, message

  while #entries > config.max_log_entries and #entries > 0
    table.remove entries, 1

export info = (message) -> dispatch 'info', message
export warning = (message) -> dispatch 'warning', message
export error = (message) -> dispatch 'error', message
export clear = -> entries = {}

return log
