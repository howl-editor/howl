# Changelog

## (in master / Unreleased)

- Avoid having the readline grow and shrink as much, which is annoying since it
requires the eyes to move up and down. Now the readline will only grow during
one read() invocation, and will keep the same fixed size regardless of the
amount of items in the completion list.

- Added howl.clipboard, new module for handling multiple clipboard items.

- Byte code compilation does not require a $DISPLAY

### VI bundle

 - Fix pasting of line block yanks (i.e. <y><y>/<Y>/<d><d>)
 - Fix count handling for yank
 - Fix <y><y> to yank current line correctly
 - Support '<' and '>' in visual mode

## 0.1.1

- Fix incompatibility with older Gtk versions.

## 0.1

First public release.
