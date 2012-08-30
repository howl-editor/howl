import command from vilu

command.register
  name: 'open',
  description: 'Open file'
  inputs: { 'file' }
  handler: (file) -> vilu.app\open_file file

command.alias 'open', 'e'
