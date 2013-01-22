_G = _G
import append, table from _G
import config from howl

config.define
  name: 'max_log_entries'
  description: 'Maximum number of log entries to keep in memory'
  default: 1000
  type_of: 'number'

log = {}
setfenv 1, log

first_line_of = (s) -> s\match '[^\n\r]*'

dispatch = (level, message) ->
  entry = :message, :level
  append entries, entry
  if _G.window
    status = _G.window.status
    readline = _G.window.readline
    status[level] status, first_line_of message
    readline\notify message, level if readline.showing
    _G.print message if level == 'error' and not _G.os.getenv('BUSTED')

  while #entries > config.max_log_entries and #entries > 0
    table.remove entries, 1

  entry

export entries = {}
export last_error = nil

export info = (message) -> dispatch 'info', message
export warning = (message) -> dispatch 'warning', message
export error = (message) -> last_error = dispatch 'error', message
export clear = ->
  entries = {}
  last_error = nil

return log
