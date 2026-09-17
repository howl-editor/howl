---
title: howl.ui.markup.howl
---

# howl.ui.markup.howl

## Overview

Howl markup is a simple markup used for easily creating [StyledText] instances.
It's a simple HTML-like markup that allows markup up specified parts of a string
with certain styles. For example:

```moonscript
m = require 'howl.ui.markup.howl'

styled_text = m('<keyword>foo</keyword>')
-- => A StyledText instance containing "foo", with the style "keyword"

styled_text = m('<keyword>foo</>')
-- => The same, ending markers can be simplified

styled_text = m('<keyword>foo</> <string>"bar"</>')
-- => A StyledText instance containing 'foo "bar"', styled as "keyword" and "string"
```

--

_See also_:

- [StyledText]
- [ActionBuffer](../action_buffer.html)
- The [spec](../../../spec/ui/markup/howl_spec.html) for Howl markup

[StyledText]: ../styled_text.html

## Functions

### (markup)

Parses the provided `markup`, and returns a [StyledText] instance.
