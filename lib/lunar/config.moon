import signal from lunar

values = {}
local_values = setmetatable {}, __mode: 'k'
defs = {}
watchers = {}

predefined_types =
  boolean: {
    options: { true, false }
    convert: (value) ->
      return value if type(value) == 'boolean'
      return true if value == 'true'
      return false if value == 'false'
      value
  },
  number: {
    convert: (value) -> tonumber(value) or value
    validate: (value) -> type(value) == 'number'
  }

broadcast = (name, value, is_local) ->
  callbacks = watchers[name]
  if callbacks
    for callback in *callbacks
      status, ret = pcall callback, name, value, is_local
      if not status
        signal.emit 'error', 'Error invoking config watcher: ' .. ret

get_def = (name) ->
  def = defs[name]
  error 'Undefined variable "' .. name .. '"', 2 if not def
  def

validate = (def, value) ->
  return if value == nil

  if def.validate and not def.validate(value)
    error 'Illegal value "' .. value .. '" for "' .. def.name .. '"'

  if def.options
    options = type(def.options) == 'table' and def.options or def.options!
    for option in *options
      option = option[1] if type(option) == 'table'
      return if option == value

    error 'Illegal option "' .. value .. '" for "' .. def.name .. '"'

convert = (def, value) ->
  if def.convert
    new_value = def.convert(value)
    return new_value if new_value != nil
  value

config = {
  definitions: defs

  define: (var = {}) ->
    for field in *{'name', 'description'}
      error '`' .. field .. '` missing', 2 if not var[field]

    if var.scope and var.scope != 'local' and var.scope != 'global'
      error 'Unknown scope "' .. var.scope .. '"', 2

    if var.type_of
      var = moon.copy var
      predef = predefined_types[var.type_of]
      error('Unknown type"' .. var.type_of .. '"', 2) if not predef
      var[k] = v for k,v in pairs predef

    defs[var.name] = var

  set: (name, value) ->
    def = get_def name

    if def.scope and def.scope == 'local'
      error 'Attempt to set a global value for local variable "' .. name .. '"', 2

    value = convert def, value
    validate def, value

    values[name] = value
    broadcast name, value, false

  set_local: (name, value, buffer) ->
    def = get_def name

    if def.scope and def.scope == 'global'
      error 'Attempt to set a local value for global variable "' .. name .. '"', 2

    value = convert def, value
    validate def, value

    if not buffer
      buffer = _G.editor.buffer if _G.editor

    error 'No buffer available for set_local', 2 if not buffer

    locals = local_values[buffer]

    if not locals
      locals = {}
      local_values[buffer] = locals

    locals[name] = value

    broadcast name, value, true

  get: (name, buffer) ->
    buffer = _G.editor.buffer if not buffer and _G.editor

    if buffer
      locals = local_values[buffer]
      if locals
        return locals[name] if locals[name] != nil

    value = values[name]
    return value if value != nil
    def = defs[name]
    return def.default if def

  reset: -> values = {}

  watch: (name, callback) ->
    list = watchers[name]
    if not list
      list = {}
      watchers[name] = list
    append list, callback
}

return setmetatable {}, {
  __index: (t, k) -> rawget(config, k) or config.get k
  __newindex: (t, k, v) ->
    if rawget config, k
      config[k] = v
    else
      config.set k, v
}
