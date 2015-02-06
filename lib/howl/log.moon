_G = _G
import table from _G
import config from howl
append = table.insert

config.define
  name: 'max_log_entries'
  description: 'Maximum number of log entries to keep in memory'
  default: 1000
  type_of: 'number'

log = {}
setfenv 1, log

essentials_of = (s) ->
  first_line = s\match '[^\n\r]*'
  essentials = first_line\match '^%[[^]]+%]:%d+: (.+)'
  essentials or first_line

dispatch = (level, message) ->
  entry = :message, :level
  append entries, entry
  window = _G.howl.app.window
  if window
    status = window.status
    readline = window.readline
    essentials = essentials_of message
    status[level] status, essentials
    readline\notify essentials, level if readline.showing
    _G.print message if level == 'error' and not _G.howl.app.args.spec

  while #entries > config.max_log_entries and #entries > 0
    table.remove entries, 1

  entry

export *
entries = {}
last_error = nil

info = (message) -> dispatch 'info', message
warning = (message) -> dispatch 'warning', message
warn = warning
error = (message) -> last_error = dispatch 'error', message
clear = ->
  entries = {}
  last_error = nil

return log
