serpent = require 'serpent'

import File from lunar.fs

cache = {}
store = nil
dirty = false

source_for = (root, rel_path) ->
  moon = root / (rel_path .. '.moon')
  return moon if moon.exists
  lua = root / (rel_path .. '.lua')
  return lua if lua.exists
  nil

get_store = ->
  home = os.getenv('HOME')
  return nil unless home
  base = File(home)\join('.lunar')

  if not base.exists
    status, err = pcall base\mkdir
    return nil unless status

  base / '.bc_cache'

save = ->
  if store and dirty
    store.contents = string.dump(loadstring(serpent.dump cache), true)

loader = (source_dir) ->
  (name) ->
    return nil unless store

    rel_path = name\gsub('%.', '/')
    source = source_for source_dir, rel_path
    return nil unless source

    bc = cache[rel_path]

    if bc and bc.modified_at >= source.modified_at
      return loadstring bc.bytecode

    f = assert loadfile source
    bytecode = string.dump f, true
    cache[rel_path] = :bytecode, modified_at: source.modified_at
    dirty = true

    return f

store = get_store!
cache = loadfile(store)! if store and store.exists

return setmetatable {}, __call: (_, source_dir) ->
  {
    loader: loader File(source_dir)
    :save
  }
