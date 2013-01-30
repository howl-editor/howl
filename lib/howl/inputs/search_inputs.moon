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

howl.inputs.register 'forward_search', ForwardSearchInput
