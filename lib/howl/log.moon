-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

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

export entries = {}

essentials_of = (s) ->
  first_line = s\match '[^\n\r]*'
  essentials = first_line\match '^%[[^]]+%]:%d+: (.+)'
  unless essentials
    essentials = first_line\match ':%d+: (.-)[\'"]?$'
  essentials or first_line

dispatch = (level, message) ->
  entry = :message, :level
  append entries, entry
  window = _G.howl.app.window
  showed_message = false

  if window and window.visible
    status = window.status
    command_line = window.command_line
    essentials = essentials_of message
    status[level] status, essentials
    command_line\notify essentials, level if command_line.showing
    showed_message = true

  -- Avoid print all sorts of random info to the terminal if it's already on the window
  if not _G.howl.app.args.spec and (not showed_message or level != 'info')
    _G.print message

  while #entries > config.max_log_entries and #entries > 0
    table.remove entries, 1

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

return log
