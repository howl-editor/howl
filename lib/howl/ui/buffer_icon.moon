{:config} = howl
{:icon} = howl.ui


config.define
  name: 'buffer_icons'
  description: 'Whether buffer icons are displayed'
  scope: 'global'
  type_of: 'boolean'
  default: true

icon.define_default 'buffer', 'nerd-square'
icon.define_default 'buffer-modified', 'nerd-pencil-square-o'
icon.define_default 'buffer-modified-on-disk', 'nerd-clone'
icon.define_default 'process-success', 'nerd-check-circle'
icon.define_default 'process-running', 'nerd-play-circle'
icon.define_default 'process-failure', 'nerd-exclamation-circle'


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
