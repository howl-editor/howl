-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

sand_box = (options = {}) ->
  env = if options.env then moon.copy options.env else {}
  chain = if options.no_globals then nil else _G
  exports = {}
  setmetatable env,
    __index: chain
    __newindex: (t, k, v) ->
      if options.no_implicit_globals
        error 'Disallowed implicit global write to "' .. k .. '"'
      else
        exports[k] = v
        rawset t, k, v

  setmetatable {
    :exports
    put: (t) => rawset env, k, v for k,v in pairs t
  },
    __type: 'Sandbox'
    __call: (f, ...) =>
      setfenv f, env
      f ...

return setmetatable {}, __call: (_, env, options) -> sand_box env, options
