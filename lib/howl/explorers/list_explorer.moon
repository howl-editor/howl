-- Copyright 2019 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

class ListItem
  new: (@item) =>
  display_row: =>
    return {@item} if type(@item) == 'string'
    return moon.copy @item

class ListExplorer
  new: (opts) =>
    error 'no items provided' unless opts.items
    @opts = moon.copy opts
  display_path: => if @opts.prompt then @opts.prompt else nil
  display_title: => if @opts.title then @opts.title else nil
  display_columns: => if @opts.columns then @opts.columns else nil
  display_items: => [ListItem(item) for item in *@opts.items]
