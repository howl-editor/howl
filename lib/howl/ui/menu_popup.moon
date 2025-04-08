-- Copyright 2012-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:List, :ListWidget, :Popup} = howl.ui
{:bindings, :config} = howl

class MenuPopup extends Popup
  new: (@items, @callback) =>
    error('Missing argument #1: items', 3) if not @items
    error('Missing argument #2: callback', 3) if not @callback

    @list = List -> @items
    @list_widget = ListWidget @list, auto_fit_width: true

    @highlight_matches_for = ''
    @list_widget\show!

    super @list_widget\to_gobject!, width: @list_widget.width, height: @list_widget.height

  refresh: =>
    @list\update @highlight_matches_for

  resize: =>
    super @list_widget.width, @list_widget.height

  choose: =>
    if self.callback @list.selection
      @close!

  on_insert_at_cursor: (editor, args) =>
    @close!
    return

  keymap: {
    down: => @list\select_next!
    ctrl_n: => @list\select_next!
    up: => @list\select_prev!
    ctrl_p: => @list\select_prev!
    page_down: => @list\next_page!
    page_up: => @list\prev_page!

    on_unhandled: (event, source, translations, self) ->
      -- if a bare modifier such as just 'ctrl', don't close popup
      return if bindings.is_modifier translations
      -- any other not character such as home or escape closes the popup
      unless event.character
        self\close!

    tab: =>
      if config.popup_menu_accept_key == 'tab'
        @choose!
      else
        false

    return: =>
      if config.popup_menu_accept_key == 'enter'
        @choose!
      else
        false
  }
