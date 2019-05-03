-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:interact} = howl

class FlatExplorer
  new: (opts={}) =>
    error "interact.select requires items table" unless opts.items and type(opts.items) == 'table'
    @items = moon.copy opts.items
    @columns = opts.columns
    @selection = opts.selection

  display_items: =>
    @items, selected_item: @selection

  display_columns: => @columns

interact.register
  name: 'select'
  description: 'Get selection made by user from a list of items'
  handler: (opts={}) ->
    interact.explore
      path: {FlatExplorer items: opts.items, columns: opts.columns, selection: opts.selection}
      prompt: opts.prompt
      text: opts.text
      title: opts.title
      auto_trim: opts.auto_trim
