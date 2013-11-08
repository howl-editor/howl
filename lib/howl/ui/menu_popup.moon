-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import BufferPopup, ActionBuffer, List from howl.ui

class MenuPopup extends BufferPopup

  new: (items, callback, list_options = {}) =>
    error('Missing argument #1: items', 3) if not items
    error('Missing argument #2: callback', 3) if not callback
    @callback = callback
    buffer = ActionBuffer!
    @list = List buffer, 1
    @list.trailing_newline = false
    @list.selection_enabled = true
    @list.items = items
    @list[k] = v for k,v in pairs list_options
    @list\show!
    super buffer

  @property items:
    get: => @list.items
    set: (items) =>
      @list\clear!
      @list.items = items
      @list\show!
      @resize!

  choose: =>
    if self.callback @list.selection
      @close!

  keymap: {
    down: => @list\select_next!
    up: => @list\select_prev!
    page_down: => @list\next_page!
    page_up: => @list\prev_page!
    return: => @choose!
  }

return MenuPopup
