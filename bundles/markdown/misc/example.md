---
title: Markdown example
---

# h1 header

# h1 header again

And h1 header again
===================

And h1 header yet again
=

But this is no header thank you
= x 2

## h2 header

And h2 header again
-------------------

### h3 header

#### h4 header

# Enough with the headers, let's crank out some syntax

## Links

Here's a [link](http://link.com).
And one with a [title](http://titled.com "Title").
And a reference style [link][ref_id]
Reference style links can have the [id] [separated]
And can omit the [ref][]

And image links
![Alt text](/path/to/img.jpg)
![Alt text][foo]

Now let's define the references:

[ref_id]: http://reflink.com
[separated]: http://separated.com
  "Separated FTW"
[ref]: <http://parens.com>     (delim!)

<http://www.autolink.com>

## Paragraphs

You can say things with *empasis*, and _underscoring_ semantics.

And if you __really__ mean it use **two** of the above.

But we choose not to lex the*m when they're em_bedded GFM style (normal now)

And this *stuff really needs to be closed on the __same line to work

## Code blocks galore

Now, look at my `code` please.

But a single ` does not a code block make

`` this is an embedded ` ``
TODO: Backtick escapes!

And my preformatted code block:
```ruby
foo
bar
```
(Clear here)

    And this is an indented code block
	And this line as well using a tab

> this is block quote

> as are *both*
these __lines__

## Lists are fun

- hey there
+ lots of markers
* are supported
1. like numbers

-but this is not a list for lack of space

   - but here we go again

    * and this is just a code block

* and list items *can* contain emphasis _et al_ as well

## Horizontal rules

- - -
yes
**********
aha
_____ _ _ _ _ _ __
well this just looks like morse

## Escaped stuff

\- not a list item

Not \_special\_ and not \*affected\*

No \`code\` here

Not a \[link](foo)

\[no ref]: http://thank-you.com
