{:signal} = howl
{:File} = howl.io

on_buffer_saved = (args) ->
  file = args.buffer.file

  -- automatically update bytecode for howl files
  if file.extension and file.extension\umatch(r'(lua|moon)') and file\is_below(howl.app.root_dir)
    bc_file = File file.path\gsub "#{file.extension}$", 'bc'
    f, err = loadfile file
    if f
      bc_file.contents = string.dump f, false
    else
      bc_file\delete! if bc_file.exists
      print err
      log.error "Failed to update byte code for #{file}: #{err}"

signal.connect 'buffer-saved', on_buffer_saved
