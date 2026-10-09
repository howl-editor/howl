-- Copyright 2012-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:List, :ListWidget, :Popup, :StyledText, :icon, :style} = howl.ui
{:bindings, :config} = howl

style.define_default 'menu_icon', 'special'

-- Font Awesome icons, drawn small, are narrower than two monospace characters
ICON_TAB_SIZE = 2

-- the row showing item, which for an item with an icon starts with the icon
-- and a tab, so that the texts after the icons line up whatever their widths
row_for = (item) ->
  return item unless type(item) == 'table' and item.icon
  first = item[1]
  first = StyledText(tostring(first), {}) unless typeof(first) == 'StyledText'
  row = [cell for cell in *item]
  row[1] = icon.get(item.icon, 'menu_icon') .. StyledText('\t ', {}) .. first
  row._menu_item = item
  row

class MenuPopup extends Popup
  new: (@items, @callback, opts = {}) =>
    error('Missing argument #1: items', 3) if not @items
    error('Missing argument #2: callback', 3) if not @callback

    @list = List -> [row_for item for item in *@items]
    @list_widget = ListWidget @list, auto_fit_width: true, tab_size: ICON_TAB_SIZE

    @highlight_matches_for = ''
    @list_widget\show!

    opts = moon.copy opts
    opts.width, opts.height = @list_widget.width, @list_widget.height
    super @list_widget\to_gobject!, opts

  refresh: =>
    @list\update @highlight_matches_for

  resize: =>
    super @list_widget.width, @list_widget.height

  choose: =>
    row = @list.selection
    item = type(row) == 'table' and row._menu_item or row
    if self.callback item
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
