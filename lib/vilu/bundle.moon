import File from vilu.fs

vilu.bundle = {}
bundle_dir = nil

init = (dir) ->
  bundle_dir = dir
  for c in *dir.children
    if c.is_directory and not c.is_hidden
      status, mod = pcall require c.basename
      vilu.bundle[mod.bundle_name or c.basename] = mod if status

file_for = (bundle, path) ->
  bundle_dir\join bundle, path

return :init, :file_for
