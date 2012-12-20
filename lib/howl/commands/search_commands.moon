import command from howl

command.register
  name: 'search-forward',
  description: 'Starts an interactive forward search'
  inputs: { '*forward_search' }
  handler: -> editor.searcher\commit!

command.register
  name: 'repeat-search',
  description: 'Repeats the last search'
  inputs: {}
  handler: -> editor.searcher\next!
