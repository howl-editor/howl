-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import app from howl

class SearchInput
  new: (@operation, @title) =>
    @searcher = app.editor.searcher

  complete: (text) =>
    @searcher[@operation] @searcher, text
    return {}, title: @title

  on_cancelled: => @searcher\cancel!
  should_complete: -> true
  close_on_cancel: -> true
  value_for: (text) => text

class ForwardSearchInput extends SearchInput
  new: => super('forward_to', 'Forward search')

class BackwardSearchInput extends SearchInput
  new: => super('backward_to', 'Backward search')

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
  name: 'replace',
  description: 'Returns a table of two values, the target text and the replacement text',
  factory: ReplaceInput
}
