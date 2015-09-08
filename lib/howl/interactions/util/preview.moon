import app, Buffer, mode from howl

get_preview_buffer = (file) ->
  for buffer in *app.buffers
    return buffer if buffer.file == file

  if file.is_directory
    buffer = Buffer {}
    buffer.title = 'Directory: '..file.basename
    buffer.text = file.path
    return buffer

  unless file.is_regular
    buffer = Buffer {}
    buffer.title = 'No preview: '..file.basename
    buffer.text = "Preview not available for #{file.type} file."
    return buffer

  buffer = Buffer mode.for_file file
  title = file.basename
  local contents
  ok, result = pcall ->
    contents = file\read 8192

  if ok
    size = file.size
    title ..= ' (~'..tostring(math.floor(size / 1024))..'KB)'
    if size == 0 or contents.is_valid_utf8
      buffer.title = "Preview: #{title}"
      buffer.text = contents or ''
    else
      buffer.title = "No Preview: #{title}"
      buffer.text = 'Preview not available.'
  else
    buffer.title = "No Preview: #{title}"
    buffer.text = result

  buffer.read_only = true
  return buffer

return { :get_preview_buffer }
