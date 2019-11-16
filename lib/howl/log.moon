-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

_G = _G
import table from _G
import config, signal from howl

append = table.insert

config.define
  name: 'max_log_entries'
  description: 'Maximum number of log entries to keep in memory'
  default: 1000
  type_of: 'number'

signal.register 'log-entry-appended',
  description: 'Signaled right after a new entry is appended to the log'
  parameters:
    essentials: 'The log message essentials'
    level: 'The log level (one of info, warning, error)'
    message: 'The log message'

signal.register 'log-trimmed',
  description: 'Signaled right after the log is trimmed to the given size'
  parameters:
    size: 'The new number of entries in the log'

log = {}
setfenv 1, log

emitting = false

safe_emit = (name, options) ->
  if emitting
    -- safe_emit called into signal.emit, which tried to log an error. Back out now
    -- to avoid a stack overflow.
    return

  emitting = true
  signal.emit name, options
  emitting = false

export entries = {}

essentials_of = (s) ->
  first_line = s\match '[^\n\r]*'
  essentials = first_line\match '^%[[^]]+%]:%d+: (.+)'
  unless essentials
    essentials = first_line\match ':%d+: (.-)[\'"]?$'
  essentials or first_line

dispatch = (level, message) ->
  essentials = essentials_of message
  entry = :essentials, :message, :level
  append entries, entry
  safe_emit 'log-entry-appended', entry

  if #entries > config.max_log_entries
    to_remove = #entries - config.max_log_entries
    for i=1,to_remove
      table.remove entries, i
    safe_emit 'log-trimmed', size: #entries

  entry

export *
last_error = nil

info = (message) -> dispatch 'info', message
warning = (message) -> dispatch 'warning', message
warn = warning
error = (message) -> last_error = dispatch 'error', message
clear = ->
  entries = {}
  last_error = nil
  signal.emit 'log-trimmed', size: 0

return log
