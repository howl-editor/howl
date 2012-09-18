dispatch = (level, message) ->
  if _G.window
    status = _G.window.status
    status[level] status, message

class Log
  info: (message) -> dispatch('info', message)
  warning: (message) -> dispatch('warning', message)
  error: (message) -> dispatch('error', message)

return Log!
