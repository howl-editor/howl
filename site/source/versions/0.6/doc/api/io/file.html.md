---
title: howl.io.File
---

# howl.io.File

## Overview

The File class provides an abstraction over a path in the file system, and
allows for querying the file for associated information as well as modifying it.

_See also_:

- The [spec](../../spec/io/file_spec.html) for File

## Class Properties

### separator

Holds the directory separator character.

## Properties

### basename

The basename of the file.

```lua
  File('/foo/base.ext').basename -- => 'base.ext'
```

### children

A list of children for the file, as File instances.

```moonscript
  children = howl.io.File('/bin/').children
  #children -- => 161
  basenames = [f.basename for f in *children]
  table.concat basenames, ', ', 1, 5 -- => "bunzip2, bzcat, bzcmp, bzdiff, bzegrep"
```

### contents

The contents of the file. Provides an easy way of reading a file's content in
one go. This is also writeable - assigning to this causes the file's content on
disk to be replaced with the assigned value.

### display_name

The basename of the file, but with a trailing separator for directories.

### etag

The "entity tag" for the file. Entity tags provides a way of determining whether
a file is changed on disk or not, and provides a more abstract alternative to
checking modified times, etc.

### exists

True if the file exists, and false otherwise.

### extension

The basename of the file name.

```lua
  File('/foo/base.ext').extension -- => 'ext'
  File('/foo/base').extension -- => nil
```

### file_type

The type of the file as a string. Possible values are:

- 'directory'
- 'regular'
- 'symlink'
- 'special'
- 'unknown'
- 'mountable'


### is_backup

True if the file is a backup file, and false otherwise.

### is_directory

True if the file's path denotes a directory, an false otherwise.

### is_hidden

True if the file is hidden, and false otherwise.

### is_link

True if the file's path denotes a symbolic link, an false otherwise.

### is_mountable

True if the file's path denotes a mountable location, and false otherwise.

### is_regular

True if the file's path denotes a regular file, and false otherwise.

### is_special

True if the file's path denotes a "special" file, such as a fifo, character
device, sockets, etc. False if not.

### modified_at

The UNIX time since the file was modified, as an unsigned 64-bit number.

```lua
  File('/bin/ls').modified_at -- => 1358406188ULL
```

### parent

The file's parent, if available, as another File instance.

```lua
  File('/foo/base.ext').parent.path -- => '/foo'
  File('/').parent -- => nil
```

### readable

True if the file is readable, and false otherwise.

### size

The size of the file, in bytes. Trying to read the size of a non-existing file
is raises an error.

### short_path

The file's path, shortened by replacing any references to the home directory
with `~`.

### writeable

True if the file is writeable, and false otherwise.

### uri

The file's path, as a URI.

```lua
  File('/foo/base.ext').uri -- => 'file:///foo/base.ext'
```

## Functions

### File(target, base_directory)

Creates a new File instance, pointing to `target`. `target` can either a string,
in which case it is considered a path, or another File instance. When target is
a string holding a relative path, `base_directory` is used for resolving the
relative path to an absolute path if given.

### copy (dest, flags)

Copies the contents of the current file to `dest`. Valid values for the `flags`
table include `COPY_OVERWRITE`, `COPY_BACKUP`, `COPY_NOFOLLOW_SYMLINKS`,
`COPY_ALL_METADATA`, `COPY_NO_FALLBACK_FOR_MOVE`, and
`COPY_TARGET_DEFAULT_PERMS`. (Their corresponding effects are documented
[here](https://developer.gnome.org/gio/stable/GFile.html#GFileCopyFlags)).

### expand_path (path)

Replaces any ocurrences `~` with the full path to the home directory.

### is_absolute (path)

Returns true if `path` is an absolute path, and false otherwise.

### tmpdir()

Returns a File instance pointing to an existing temporary directory. The
directory will not be automatically deleted.

### tmpfile()

Returns a File instance pointing to an existing temporary file. The file will
not be automatically deleted.

### with_tmpfile (callback)

Invokes `callback` with a File instance pointing to an existing temporary file.
The temporary file will be automatically deleted upon the return of `callback`,
if it exists.

## Methods

### delete ()

Deletes the file. Raises an error if unsuccesful.

### delete_all ()

For a directory, delete the directory and all files contained within it. Raises
an error if unsuccesful.

### find (options = {})

For a directory, returns all files within the directory or any sub directory of
the directory. In addition to the files, a boolean is returned indicated whether
the result is partial or not (`true` indicating a partial result and `false` a
complete result). The result will always be complete, unless the execution is
prematurely halted by use of the `on_enter` option. `options` allows for
additional control of the operation, and can contain the following fields:

- `filter`: A callback that will recieve each file as its sole argument. To
filter a file, i.e. exclude it from the results, the callback should return
true. The search is performed breadth first, so filtering a directory means that
it won't be descended into at all.

- `sort`: Causes the entries of all directories to be sorted before processing.

- `on_enter`: If given, this function is invoked each time a new directory is
entered (including the first one). The function is passed the directory to
enter, as well as the found files so far. This function can also optionally
cancel the execution, by return the special return value 'break'. If this is
done, execution is ended and a partial result is returned.

### find_paths (options = {})

For a directory, returns the relative paths of all files or sub directories
within the directory. In addition to the paths, a boolean is returned indicated
whether the result is partial or not (`true` indicating a partial result and
`false` a complete result). The result will always be complete, unless the
execution is prematurely halted by use of the `on_enter` option. In contrast to
[find](#find) this will return a table of strings, and not files. Compared to
find this is also a much more performant operation if all you want is a list of
directories or files. In order to get any detailed information about type, etc.,
you will have to instantiate File object, but the basic type of entry (directory
or other) can be deduced by looking at end of any path - directories have a
trailing separator. No guarantees are given with regards to the order of the
returned entries.

`options` allows for additional control of the operation, and can contain the
following fields:

- `exclude_directories` This will not return paths for any sub directories. The
directories themselves will still be traversed however.

- `exclude_non_directories` This will not return paths for any non-directory
path entries.

- `filter`: A callback that will recieve each relative path as its sole
argument. To filter a path, i.e. exclude it from the results, the callback
should return true. Note that filtering a directory means that it won't be
descended into at all.

- `on_enter`: If given, this function is invoked each time a new directory is
entered (including the first one). The function is passed the relative path of
the directory to enter, as well as the found paths so far. This function can
also optionally cancel the execution, by return the special return value
'break'. If this is done, execution is ended and a partial result is returned.

-
Example:

Given the following directory structure:

```
/tmp/foo
  child1.lua
  sub/
    sub_child.txt
  child2.lua

```

You can expect the following results (order is not defined however):

```lua
howl.io.File('/tmp/foo'):find_paths()
-- =>
{
  'child1.lua',
  'child2.moon',
  'sub/'
  'sub/sub_child.txt'
}

```


### is_below (directory)

Returns true if the file is located below `directory`, and false otherwise.

### join (...)

Joins the file with any path components passed in as parameters, and returns a
new File pointing to the resulting path.

### mkdir ()

Creates a new directory at the path denoted by the file. Raises an error if
unsuccesful.

### mkdir_p ()

Creates a new directory at the path denoted by the file, including any
non-existing intermediate directories. Raises an error if unsuccesful.

### open (mode = 'r', callback = nil)

Opens the file in the mode specified by `mode`, and returns the Lua file
descriptor. Any error when opening the file causes an error to be raised.

When `callback` is specified it is invoked with the file descriptor, and any
return values from the callback are used as the return values for `open`. The
file description will in this case always be closed prior to `open` returning.

### read (...)

A quick way of issuing a Lua
[read](http://www.lua.org/manual/5.1/manual.html#pdf-file:read) call for the
file. This will open the file for reading, issue the read call, and close the
file before returning the resulting values.

### relative_to_parent (parent)

Returns the path for the current file relative to its parent.

```lua
File('/bin/ls'):relative_to_parent(File('/bin')) -- => 'ls'
```

### rm ()

Alias for [delete](#delete).

### rm_r ()

Alias for [delete_all](#delete_all).

### touch ()

Ensures that the file exists, by creating it if not already present.

### unlink ()

Alias for [delete](#delete).

## Meta methods

In addition to the above properties and methods, File instances also responds to
certain meta methods.

### Joining files

Apart from using the [join](#join) method, File instances can also be joined by
using the `/` operator or the `..` operator:

```lua
(File('/bin') / 'ls').path -- => '/bin/ls'
(File('/bin') .. 'ls').path -- => '/bin/ls'
```

Concatenating a File instance to a string returns a string though:

```lua
"File is " .. File('/bin') -- => 'File is /bin'
```

### Files as strings

Files respond to the tostring meta method:

```lua
tostring(File('/bin/ls')) -- => '/bin/ls'
```

### Comparing files

Files can be lexically compared to other File instances.

```lua
File('/bin/ls') == File('/bin/ls') -- => true
File('/bin/ls') == File('/bin/cat') -- => false
File('/bin/ls') < File('/bin/cat') -- => false
File('/bin/ls') > File('/bin/cat') -- => true
```

[regex]: ../regex.html
