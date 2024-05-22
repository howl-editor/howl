---
title: howl.ui.StyledText
---

# howl.ui.StyledText

## Overview

StyledText is a container that holds text as well as the text's associated
styling. Its primarily used with [ActionBuffer]s for easily inserting styled
contents. While you can construct StyledText instances manually, it's often more
convenient to create these from markup, e.g. using [Howl
markup](markup/howl.html).

---

_See also_:

- The [Buffer] class which ActionBuffer is based upon
- The [spec](../../spec/ui/styled_text_spec.html) for StyledText

[ActionBuffer]: action_buffer.html

## Constructors

### StyledText (text, styles_or_style)

Creates a new `StyledText` instance, holding the specified `text` and
`styles_or_style`. Here `text` is a string containing the content and
`styles_or_style` is either a string specifying a single style or a table as
described in [properties](#properties) below. When `styles_or_style` is passed
as a string a correct [styles](#styles) will automatically be generated for the
StyledText object.

### StyledText.for_table (items, columns=nil)

Creates and returns a new `StyledText` instance holding content laid out as a
table.

`items` is a table containing rows. Each row can either be a cell representing a
single column, or a table of cells representing multiple columns. Each cell
should be either a string or a `StyledText` object, or an object that can be
converted to either one of them. If the object needs to be converted and the
object's metatable contains a `__tostyled` meta method, that is invoked and the
return value assumed to be a `StyledText` object. Otherwise the object is
converted to a string using `tostring`.

`columns` is an optional table containing header and style information for the
columns. It is a table containing one or more column definitions. Each column
definition is a table with two fields:

- `header`: a cell containing the header text
- `style`: a style name specifying the default style for all cells in the
column. This style is used for any cell in the column that is a string and not a
`StyledText`.

In addition to the `StyledText` instance returned, `for_table` also returns a
table containing the starting positions of the styled tables columns.

The following example generates a table with column headers and column styles:

```moonscript
my_buffer = howl.ui.ActionBuffer!
my_buffer\append howl.ui.StyledText.for_table {
    {'red', 'Error'},
    {'orange', 'Warning'},
    {'blue', 'Information'}
  },
  { {header: 'Color', style: 'string'},
    {header: 'Level', style: 'comment'}
  }
```

## Properties

### styles

The styles for the contained [text]. `styles` is a table containing consecutive
triplets, each specifying a particular style for a certain range. A triplets
consists of a starting position, a style name and an ending position (not
included in the range). Note that unlike most other parts of the Howl API, these
positions are byte positions and not character positions.

To better understand the structure, consider the following example:

```lua
local styles = { 1, 'operator', 2, 3, 'keyword', 6 }
styled_text = StyledText('! foo 2', styles)
```
In the example above, "!" would be styled as an operator, while "foo" would be
styled as a keyword. All other parts, such as the white space and "2", would be
unstyled.

### text

The contained text.

## Meta methods

### tostring

StyledText instances respond to `tostring`, returning the [text] part.

### Concatenation

StyledText instances can be concatenated with strings, returning the resulting
concatenation of [text] and the specified string.

StyledText instances can be concatenated with other StyledText instances
returning a new StyledText instance.

### Length operator (#)

The length operator returns the length of the [text].

[text]: #text

### Comparison

StyledText instances can be compared for equality with other StyledText
instances, with the comparison evaluating to true if both the text part and
corresponding styles match exactly.

