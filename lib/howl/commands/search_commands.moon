-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

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

command.register
  name: 'replace',
  description: 'Replaces text (within selection or globally)'
  inputs: { 'replace' }
  handler: (values) ->
    { target, replacement } = values
    chunk = editor.active_chunk
    chunk.text, count = chunk.text\gsub target, replacement
    if count > 0
      log.info "Replaced #{count} occurrences of '#{target}' with '#{replacement}'"
    else
      log.warn "No occurrences of '#{target}' found"
