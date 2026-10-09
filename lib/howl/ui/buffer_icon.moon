{:config} = howl
{:icon} = howl.ui


config.define
  name: 'buffer_icons'
  description: 'Whether buffer icons are displayed'
  scope: 'global'
  type_of: 'boolean'
  default: true

icon.define_default 'buffer', 'nerd-cod-file'
icon.define_default 'buffer-modified', 'nerd-cod-circle-filled'
icon.define_default 'buffer-modified-on-disk', 'nerd-cod-sync'
icon.define_default 'process-success', 'nerd-cod-pass'
icon.define_default 'process-running', 'nerd-cod-play-circle'
icon.define_default 'process-failure', 'nerd-cod-error'


buffer_status_icon = (buffer) ->
  local name
  if typeof(buffer) == 'ProcessBuffer'
    if buffer.process.exited
      name = buffer.process.successful and 'process-success' or 'process-failure'
    else
      name = 'process-running'
  else
    if buffer.modified_on_disk
      name = 'buffer-modified-on-disk'
    elseif buffer.modified
      name = 'buffer-modified'
    else
      name = 'buffer'

  return icon.get(name, 'operator')

{
  :buffer_status_icon
}
