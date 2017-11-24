-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- This is the crudest version of an lfs implementation that allows Howl
-- to run busted for the specs

{:File} = howl.io

get_file_mode = (f) ->
  mapping = {
    directory: 'directory',
    regular: 'file'
  }
  mapping[f.file_type] or 'other'

attributes = (path, name, table) ->
  f = File path
  if name
    if name == 'mode'
      return get_file_mode f
    return nil, "Unsupported attribute '#{name}'"

  error "howl-lfs-shim: Unsupported operation"

dir = (path) ->
  f = File path
  assert f.is_directory, "Not a directory: '#{path}'"
  kids = [c.basename for c in *f.children]
  i = 0
  setmetatable {}, {
    __call: ->
      i += 1
      kids[i]
  }


:attributes, :dir

