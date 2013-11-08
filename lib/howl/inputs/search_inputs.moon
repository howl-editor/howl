-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

class SearchInput
  new: (@operation, @title) =>
    @searcher = editor.searcher

  complete: (text) =>
    @searcher[@operation] @searcher, text
    return {}, title: @title

  on_cancelled: => @searcher\cancel!
  should_complete: -> true
  close_on_cancel: -> true
  value_for: (text) => text

class ForwardSearchInput extends SearchInput
  new: => super('forward_to', 'Forward search')

class ReplaceInput
  close_on_cancel: -> true

  on_submit: (text, readline) =>
    unless @target
      @target = text
      readline.prompt ..= "'#{text}' with "
      readline.text = ''
      false

  value_for: (text) => { @target, text }

howl.inputs.register 'forward_search', ForwardSearchInput
howl.inputs.register 'replace', ReplaceInput
