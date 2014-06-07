-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import app from howl

class SearchInput
  new: (@operation, @type, @title) =>
    @searcher = app.editor.searcher
    @keymap = {
      [howl.bindings.binding_for('buffer-search-backward', 'editor')]: ->
        @searcher\previous!
      [howl.bindings.binding_for('buffer-search-forward', 'editor')]: ->
        @searcher\next!
      up: -> @searcher\previous!
      down: -> @searcher\next!
    }

  complete: (text) =>
    @searcher[@operation] @searcher, text, @type
    return {}, title: @title

  on_cancelled: => @searcher\cancel!
  should_complete: -> true
  close_on_cancel: -> true
  value_for: (text) => text

class ForwardSearchInput extends SearchInput
  new: => super('forward_to', 'plain', 'Forward search')

class BackwardSearchInput extends SearchInput
  new: =>
    super('backward_to', 'plain', 'Backward search')

class SearchWordInput extends SearchInput
  new: (operation, type, title) =>
    super(operation, type, title)
    @keymap = {
      [howl.bindings.binding_for('buffer-search-word-backward', 'editor')]: ->
        @searcher\previous!
      [howl.bindings.binding_for('buffer-search-word-forward', 'editor')]: ->
        @searcher\next!
      up: -> @searcher\previous!
      down: -> @searcher\next!
    }

  on_readline_available: (input, readline) ->
    readline.text = app.editor.current_context.word.text

class ForwardSearchWordInput extends SearchWordInput
  new: => super('forward_to', 'word', 'Forward word search')

class BackwardSearchWordInput extends SearchWordInput
  new: => super('backward_to', 'word', 'Backward word search')

class ReplaceInput
  close_on_cancel: -> true

  on_submit: (text, readline) =>
    unless @target
      @target = text
      readline.prompt ..= "'#{text}' with "
      readline.text = ''
      return false

    true

  value_for: (text) => { @target, text }

howl.inputs.register {
  name: 'forward_search',
  description: 'An input that interactively searches forward from cursor for the input text',
  factory: ForwardSearchInput
}

howl.inputs.register {
  name: 'backward_search',
  description: 'An input that interactively searches backwards from cursor for the input text',
  factory: BackwardSearchInput
}

howl.inputs.register {
  name: 'forward_search_word',
  description: 'An input that interactively searches forward from cursor for the input word',
  factory: ForwardSearchWordInput
}

howl.inputs.register {
  name: 'backward_search_word',
  description: 'An input that interactively searches backwards from cursor for the input word',
  factory: BackwardSearchWordInput
}

howl.inputs.register {
  name: 'replace',
  description: 'Returns a table of two values, the target text and the replacement text',
  factory: ReplaceInput
}
