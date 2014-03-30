-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import app, Buffer, command, mode from howl
import BufferPopup from howl.ui

command.register
  name: 'buffer-search-forward',
  description: 'Starts an interactive forward search'
  inputs: { '*forward_search' }
  handler: -> app.editor.searcher\commit!

command.alias 'buffer-search-forward', 'search-forward', deprecated: true

command.register
  name: 'buffer-repeat-search',
  description: 'Repeats the last search'
  inputs: {}
  handler: -> app.editor.searcher\next!

command.alias 'buffer-repeat-search', 'repeat-search', deprecated: true

command.register
  name: 'buffer-replace',
  description: 'Replaces text (within selection or globally)'
  inputs: { '*replace' }
  handler: (values) ->
    { target, replacement } = values
    escaped = target\gsub '[%p%%]', '%%%1'
    escaped_replacement = replacement\gsub('%%%d', '%%%1')
    chunk = app.editor.active_chunk
    chunk.text, count = chunk.text\gsub escaped, escaped_replacement
    if count > 0
      log.info "Replaced #{count} occurrences of '#{target}' with '#{replacement}'"
    else
      log.warn "No occurrences of '#{target}' found"

command.alias 'buffer-replace', 'replace', deprecated: true

command.register
  name: 'buffer-replace-pattern',
  description: 'Replaces text using Lua patterns (within selection or globally)'
  inputs: { '*replace' }
  handler: (values) ->
    { target, replacement } = values
    chunk = app.editor.active_chunk
    chunk.text, count = chunk.text\gsub target, replacement
    if count > 0
      log.info "Replaced #{count} occurrences of '#{target}' with '#{replacement}'"
    else
      log.warn "No occurrences of '#{target}' found"

command.alias 'buffer-replace-pattern', 'replace-pattern', deprecated: true

command.register
  name: 'show-doc-at-cursor',
  description: 'Shows documentation for symbol at cursor, if available'
  handler: ->
    m = app.editor.buffer.mode
    ctx = app.editor.current_context
    if m.api and m.resolve_type
      node = m.api
      path, parts = m\resolve_type ctx

      if path
        node = node[k] for k in *parts when node

      node = node[ctx.word.text] if node

      if node and node.description
        buf = Buffer mode.by_name('markdown')
        buf.text = node.description
        app.editor\show_popup BufferPopup buf
        return

    log.info "No documentation found for '#{ctx.word}'"

command.register
  name: 'force-mode',
  description: 'Forces a specified mode for the current buffer'
  inputs: { 'mode' }
  handler: (mode) ->
    buffer = app.editor.buffer
    buffer.mode = mode
    log.info "Forced mode '#{mode.name}' for buffer '#{buffer}'"
