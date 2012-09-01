import command from lunar

command.register
  name: 'open',
  description: 'Open file'
  inputs: { 'file' }
  handler: (file) -> lunar.app\open_file file

command.alias 'open', 'e'
