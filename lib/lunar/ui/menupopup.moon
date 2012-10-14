import BufferPopup, ActionBuffer, List from lunar.ui

class MenuPopup extends BufferPopup

  new: (items, callback) =>
    error('Missing argument #1: items', 3) if not items
    error('Missing argument #2: callback', 3) if not callback
    @callback = callback
    buffer = ActionBuffer!
    @list = List buffer, 1
    @list.items = items
    @list.trailing_newline = false
    @list.selection_enabled = true
    @list\show!
    super buffer

  choose: =>
    self.callback @list.selection
    @close!

  keymap: {
    down: => @list\select_next!
    up: => @list\select_prev!
    page_down: => @list\next_page!
    page_up: => @list\prev_page!
    return: => @choose!
  }

return MenuPopup
