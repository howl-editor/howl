# Changelog

## In master (unreleased)

- Avoid having the readline grow and shrink as much, which is annoying since it
requires the eyes to move up and down. Now the readline will only grow during
one read() invocation, and will keep the same fixed size regardless of the
amount of items in the completion list.

- Added howl.clipboard, new module for handling multiple clipboard items.

- Removed fuzzy matching. It was noisy, and added little value.

### Bugs

- Completion popup now closes upon entering a non-character

- Buffer grep fixed for buffers with empty lines

- Byte code compilation no longers requires a $DISPLAY

- Overly long lines in the readline are now shortened to avoid horizontal
scrolling.

- `buffer-replace` command now works correctly with an empty replacement string.

### VI bundle

- Fix pasting of line block yanks (i.e. <y><y>/<Y>/<d><d>)
- Fix count handling for yank
- Fix <y><y> to yank current line correctly
- Support '<' and '>' in visual mode

## 0.1.1 (2014-03-15)

- Fix incompatibility with older Gtk versions.

## 0.1 (2014-03-15)

First public release.
