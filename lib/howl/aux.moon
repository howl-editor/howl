util = howl.util

setmetatable {}, {
  __index: (key) =>
    tb = debug.traceback '', 2
    first = tb\match 'stack traceback:\n%s*([^\n]+)'
    log.error "`howl.aux` is deprecated, please update your code to use `howl.util` instead\n  (#{first})\n"
    util[key]
}
