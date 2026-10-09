---
title: howl.ui.MenuPopup
---

# howl.ui.MenuPopup

## Overview

A MenuPopup is a [Popup] displaying a list of items for the user to choose from.
It's shown in an editor using the [Editor]'s `show_popup` method:

```moonscript
menu = howl.ui.MenuPopup {'one', 'two', 'three'}, (item) ->
  log.info "Chose #{item}"
  true
howl.app.editor\show_popup menu, persistent: true
```

While showing, `down`/`ctrl_n` and `up`/`ctrl_p` move the selection, and
`page_down` and `page_up` move it a page at a time. The selected item is chosen
with `tab` or `enter`, depending on the `popup_menu_accept_key` configuration
variable. Any other key that doesn't insert a character, such as `escape`,
closes the popup, while pressing a modifier key alone doesn't. A key that inserts
a character is passed on to the editor, which closes the popup as the character
is inserted.

---

_See also_:

- The [Popup] class which MenuPopup is based upon
- The [CompletionPopup], a MenuPopup for completions
- The [spec](../../spec/ui/menu_popup_spec.html) for MenuPopup

## Constructor

### MenuPopup (items, callback, opts = {})

Creates a new MenuPopup for `items`, a list of the items to show. Items are
displayed as for a [List]: strings, or tables with one value per column. A table
item can have an `icon` field naming an icon from `howl.ui.icon`, such as
`'font-awesome-cube'`, which is shown before its first
column using the `menu_icon` style. The text after the icons is lined up, however
wide each icon is.

`callback` is invoked with the selected item when an item is chosen. The popup
is closed if `callback` returns true.

`opts` are the options for the underlying [Popup], such as `css_class`. A menu
opened by an explicit action, rather than while typing, should set it to
`action-popup`:

```moonscript
items = {
  { 'Definition', icon: 'goto-definition' },
  { 'References', icon: 'goto-reference' }
}
menu = howl.ui.MenuPopup items, ((item) -> log.info "Chose #{item[1]}"; true),
  css_class: 'action-popup'
howl.app.editor\show_popup menu
```

## Properties

### items

The list of items. After changing it, call [refresh](#refresh) to update the
displayed list.

### list

The [List] displaying the items.

### highlight_matches_for

Text to highlight within the items when refreshed, e.g. the text typed so far.

## Methods

### choose ()

Chooses the selected item, invoking the callback.

### refresh ()

Updates the displayed list from `items`, highlighting any matches for
`highlight_matches_for`.

### resize ()

Resizes the popup to fit the displayed list.

[CompletionPopup]: completion_popup.html
[Editor]: editor.html
[List]: list.html
[Popup]: popup.html
