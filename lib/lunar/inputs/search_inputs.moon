class SearchInput
  new: (operation) =>
    @operation = operation
    @searcher = editor.searcher

  on_cancelled: => @searcher\cancel!
  should_complete: => true
  complete: (text) => @searcher[@operation] @searcher, text
  value_for: (text) => text

class ForwardSearchInput extends SearchInput
  new: => super('forward_to')

lunar.inputs.register 'forward_search', ForwardSearchInput
