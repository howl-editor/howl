---
title: howl.ui.StyledText
---

# howl.ui.StyledText

## Overview

StyledText is a container that holds text as well as the text's associated
styling. Its primarily used with [ActionBuffer]s for easily inserting styled
contents. While you can construct StyledText instances manually, it's more
convenient to create these from markup, e.g. using [Howl
markup](markup/howl.html).

---

_See also_:

- The [Buffer] class which ActionBuffer is based upon
- The [spec](../../spec/ui/styled_text_spec.html) for StyledText

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

## Functions

### StyledText(text, styles)

Creates a new StyledText instance, holding the specified text and styles.

[ActionBuffer]: action_buffer.html

## Meta methods

### tostring

StyledText instances respond to `tostring`, returning the [text] part.

### Concatenation

StyledText instances can be concatenated with strings, returning the resulting
concatenation of [text] and the specified string.

### Length operator (#)

The length operator returns the length of the [text].

[text]: #text

### Comparison

StyledText instances can be compared for equality with other StyledText
instances, with the comparison evaluating to true if both the text part and
corresponding styles match exactly.
