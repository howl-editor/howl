-- Copyright 2025 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- Case-insensitive, order-preserving HTTP header collection.
--
-- Pure Lua: no FFI and no I/O, so it specs without a socket. Header names compare
-- case-insensitively per RFC 9110, but the casing a caller used is preserved for
-- serialisation. Repeated headers are kept as a list - scalar lookup returns the
-- last value, `\all` returns every one. Set-Cookie must never be comma-joined,
-- which is why the list is not collapsed.

append = table.insert

-- RFC 9110 token: alphanumerics plus "!#$%&'*+-.^_`|~". Notably excludes ':',
-- whitespace, CR and LF, which is what makes header injection impossible.
TOKEN_PATTERN = "^[%w!#%$%%&'%*%+%-%.%^_`|~]+$"

is_valid_name = (name) ->
  return false unless type(name) == 'string'
  name\match(TOKEN_PATTERN) != nil

is_valid_value = (value) ->
  return false unless type(value) == 'string'
  return false if value\find '[\r\n]'
  return false if value\find '\0', 1, true
  -- leading/trailing whitespace is stripped by every recipient anyway, and
  -- allowing it invites confusion about what was actually sent
  return false if value\match('^%s') or value\match('%s$')
  true

validate_name = (name) ->
  unless is_valid_name name
    error "invalid HTTP header name: #{string.format '%q', tostring name}", 3
  name

validate_value = (name, value) ->
  unless is_valid_value value
    error "invalid value for HTTP header '#{name}': #{string.format '%q', tostring value}", 3
  value

-- A method name here shadows a header of the same name on scalar lookup. None of
-- these collide with a real HTTP header, and `\all` is worth the trade.
new_headers = (initial) ->
  entries = {}  -- { {name: name, value: value}, ... } in wire order
  index = {}    -- lower(name) -> { value, ... }

  h = nil

  add = (name, value) ->
    name = tostring name
    value = tostring value
    key = name\lower!
    append entries, {:name, :value}
    index[key] or= {}
    append index[key], value
    h

  remove = (name) ->
    key = tostring(name)\lower!
    return h unless index[key]
    index[key] = nil
    kept = [e for e in *entries when e.name\lower! != key]
    entries = kept
    h

  set = (name, value) ->
    remove name
    add name, value

  -- Fat arrows throughout: these are reached as `h\method(...)`, so the receiver
  -- arrives as the first argument and has to be absorbed by `@`.
  get = (name) ->
    vs = index[tostring(name)\lower!]
    vs and vs[#vs] or nil

  instance_methods = {
    add: (name, value) => add name, value
    set: (name, value) => set name, value
    remove: (name) => remove name

    -- last value wins, matching what a scalar lookup means to a caller
    get: (name) => get name

    all: (name) =>
      vs = index[tostring(name)\lower!]
      return {} unless vs
      [v for v in *vs]

    has: (name) => index[tostring(name)\lower!] != nil

    count: => #entries

    -- iterates every header line, duplicates included, in wire order
    each: =>
      i = 0
      ->
        e = entries[i + 1]
        return nil unless e
        i += 1
        e.name, e.value

    -- a plain { name: value } snapshot, lower-cased; duplicates collapse to the last
    to_table: =>
      t = {}
      for key, vs in pairs index
        t[key] = vs[#vs]
      t
  }

  h = setmetatable {}, {
    __index: (t, key) ->
      m = instance_methods[key]
      return m if m
      return nil unless type(key) == 'string'
      vs = index[key\lower!]
      vs and vs[#vs] or nil

    __newindex: (t, key, value) ->
      if value == nil
        remove key
      else
        set key, value

    __len: -> #entries
  }

  if initial
    for name, value in pairs initial
      add name, value

  h

{
  create: new_headers
  :is_valid_name
  :is_valid_value
  :validate_name
  :validate_value
}
