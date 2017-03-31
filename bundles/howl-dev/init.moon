{:signal, :config} = howl
{:File} = howl.io

is_under_src_directory = (file) ->
  return true if file\is_below(howl.app.root_dir)
  if config.howl_src_dir
    src_dir = File config.howl_src_dir
    return file\is_below(src_dir)

  false

on_buffer_saved = (args) ->
  file = args.buffer.file

  -- automatically update bytecode for howl files
  if file.extension and
    file.extension\umatch(r'(lua|moon)') and
    is_under_src_directory(file)

    bc_file = File file.path\gsub "#{file.extension}$", 'bc'
    f, err = loadfile file
    if f
      bc_file.contents = string.dump f, false
    else
      bc_file\delete! if bc_file.exists
      log.error "Failed to update byte code for #{file}: #{err}"

config.define {
  name: 'howl_src_dir',
  description: 'Optional path to Howl src directory [development]',
  scope: 'global'
}

signal.connect 'buffer-saved', on_buffer_saved

info = {
  author: 'The Howl Developers',
  description: 'Howl development bundle',
  license: 'MIT',
}

unload = ->
  signal.disconnect 'buffer-saved', on_buffer_saved

return :info, :unload
