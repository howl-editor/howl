---
title: New and Improved Search Commands
location: San Francisco, California, USA
---

Among a slew of updates in the last few months, the [Howl
editor](http://howl.io) has received some exciting enhancements to its search
capabilities in the unreleased [master
branch](https://github.com/nilnor/howl/commits/master).

READMORE

## Searching Backwards and Jumping Around

Firstly, a new command called `buffer-search-backward` - bound to `ctrl_r` -
implements a fast backwards interactive search. Just invoke it and type away to
find the previous occurrence of whatever text you are typing.

Secondly, both `buffer-search-forward` (`ctrl_f`) and `buffer-search-backward`
now highlight all matches, while still highlighting the primary match with a
different style:

![backward search](blog/improved-search-commands/backward-search.png)

What makes this even more useful is that you can press `ctrl_f` or `ctrl_r`
again, while the search is active, to quickly jump to the next or previous
match (the up and down arrow keys can be used as well).

As with the original search command, hitting `enter` at any point moves your
cursor to the currently highlighted primary match, while hitting `esc` reverts
it to its original position.

## Matching Whole Words

Plain searches are nice but not very effective when you want to look for *whole
words*, such as identifiers in code that could be sub-strings of other
identifiers.

Two new commands - `buffer-search-word-forward` and `buffer-search-word-backward`
(bound to `ctrl_period` and `ctrl_comma`) - match whole words only. They highlight
all occurrences of the current word at cursor. The word is determined by the
configured word pattern which depends on the current mode and the buffer.

In short, you can position your cursor on a word that interests you and hit
`ctrl_period` to highlight all visible occurrences of the same word, as you can
see here:

![search word forward](blog/improved-search-commands/search-word-forward.png)

Using `ctrl_comma` does the same but also jumps to the previous matching word.
Similar to the other search commands, jumping to the next or previous match is
as simple as using the up or down arrow keys.

Hope you enjoy these enhancements! Stay tuned for more news about other exciting
updates.
