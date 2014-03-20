---
title: howl.clipboard
---

# howl.clipboard

## Overview

The clipboard module keeps track of copied text in Howl, and handles
synchronization with the system clipboard. It provides two ways of remembering
clipboard items: As a list of anynomous clips that is automatically updated with
each copy/delete/cut operation, and within named registers.

### Clipboard items

A clipboard item is a simple Lua table. The simplest and most common type of
item contains only one field, `text`, that contains the text of the item. There
is no real restriction on what additional fields can be available for a
clipboard item (the fields can be specified when doing a [push](#push)), but so
far one specific field is in use; The `whole_lines` field, when set to `true`,
indicates that the text should be considered a block of stand-alone lines,
rather than a simple chunk of text.

---

_See also_:

- The [spec](../spec/clipboard_spec.html) for clipboard

## Properties

### clips

A table (list) of clipboard items available on the clipboard, with the most
recent item being at index 1 in the table. The maximum number of clipboard items
is controlled by the `clipboard_max_items` config variable. `clips` is
automatically updated whenever a new item is [push()ed](#push), prepending the
new item and removing older items as necessary.

### current

The most recent anynomous clipboard item available on the clipboard.

### registers

A table containing named clipboard items. As an example, suppose a clipboard
item containing the text "hello" has been [push()ed](#push) to the `abc`
register. In that case the `registers` table would look like the following:

```lua
{
  abc = {
    text: 'hello'
  }
}
```


## Functions

### push (item, options = {})

Pushes the specified `item` to the clipboard. `item` can either be table
containing a `text` field, along with optional additional fields, or it can be a
string in which case a clipboard item table is automatically constructed.

The optional `options` table allows for specifying a named register where to
store the item. The `to` field specifies the register name to use for storing
the clip in this case.

The pushed item is made available to the system clipboard automatically, except
when pushing to a named register using the `to` field in `options`.

_Examples_:

```lua
-- Push some text to the clipboard
howl.clipboard.push('my text')

-- Push a clipboard item with additional fields
howl.clipboard.push({text = 'my text', whole_lines = true})

-- Push some text to the register 'a'
howl.clipboard.push('my text', { to = 'a' } )
```
