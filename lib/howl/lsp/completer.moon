-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

lsp = require 'howl.lsp'

TRIGGER_INVOKED = 1
TRIGGER_CHARACTER = 2
TRIGGER_INCOMPLETE = 3

completion_text = (item) ->
  edit = item.textEdit
  edit and edit.newText or item.insertText or item.label

to_completion = (item) ->
  {
    item.label,
    completion: completion_text(item),
    filter: (item.filterText or item.label).ulower,
    sort: item.sortText or item.label
  }

to_completions = (result) ->
  return {}, false unless result
  items = result.items or result
  completions = [to_completion(i) for i in *items when i.label]
  table.sort completions, (a, b) -> a.sort < b.sort
  completions, result.isIncomplete == true

-- Completions are requested asynchronously: `complete` returns what is
-- available straight away, and `on_update` is invoked once a response
-- arrives so that the completions can be fetched again.
class LspCompleter
  new: (buffer, context, on_update) =>
    @buffer = buffer
    @state = buffer.data.lsp
    @client = @state.client
    @on_update = on_update
    start_pos = context.word.start_pos
    if start_pos > 1
      char = buffer\sub start_pos - 1, start_pos - 1
      triggers = @client.completion_triggers
      @trigger = char if triggers and triggers[char]

  complete: (context) =>
    prefix = context.word_prefix
    if @_needs_request prefix
      @_request context

    unless @items
      -- when triggered by a trigger character, such as '.', suppress other
      -- completers' guesses until we know what the server has to say
      return @trigger and { authoritive: true } or {}

    prefix = prefix.ulower
    completions = [c for c in *@items when c.filter\find(prefix, 1, true) == 1]
    completions.authoritive = true if @trigger and not @failed
    completions

  _needs_request: (prefix) =>
    return true unless @requested_prefix
    return false if @failed
    -- the cached items were for a longer prefix
    return true unless prefix\find(@requested_prefix, 1, true) == 1
    @incomplete and prefix != @requested_prefix

  _request: (context) =>
    @client\cancel @_request_id if @_request_id
    lsp.sync @buffer

    trigger_kind = if @requested_prefix and @incomplete
      TRIGGER_INCOMPLETE
    elseif @trigger and context.pos == context.word.start_pos
      TRIGGER_CHARACTER
    else
      TRIGGER_INVOKED

    params = {
      textDocument: { uri: @state.uri },
      position: lsp.position(@buffer, context.pos),
      context: {
        triggerKind: trigger_kind,
        triggerCharacter: trigger_kind == TRIGGER_CHARACTER and @trigger or nil
      }
    }

    @requested_prefix = context.word_prefix
    local id
    id = @client\send_request 'textDocument/completion', params, (result, err) ->
      return unless @_request_id == id
      @_request_id = nil
      if err
        @failed = true
        @items or= {}
      else
        @items, @incomplete = to_completions result

      @.on_update! if @on_update

    @_request_id = id
    unless id
      @failed = true
      @items or= {}

howl.completion.register {
  name: 'lsp',
  factory: (buffer, context, on_update) ->
    state = lsp.attach buffer
    return nil unless state
    client = state.client
    return nil if client.initialized and not client.capabilities.completionProvider
    LspCompleter buffer, context, on_update
}

LspCompleter
