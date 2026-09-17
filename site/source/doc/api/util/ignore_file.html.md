---
title: howl.util.ignore_file
---

# howl.util.ignore_file

## Overview

howl.util.ignore_file provides support for "ignore files", more specifically Git
ignore files (e.g. `.gitignore`) and the ignore files used by searchers such as
[ripgrep](https://github.com/BurntSushi/ripgrep) and [The Silver
Searcher](https://geoff.greer.fm/ag/) (i.e. `.ignore`). The purpose of ignore
files is ignore certain files or directories within a target directory. This is
accomplished by having one or more ignore files in the target directory, either
at the root or in any arbitrary sub directory, containing patterns which specify
what to ignore. You can read more about ignore files in the
[manpage for gitignore](https://git-scm.com/docs/gitignore).

This module has been written to handle all of the known cases for ignore files
at the time of this writing. This includes negations, escapes, all different
types of globs, correct handling of sub directory ignore files, etc. Any missing
functionality should thus be considered a bug, so please report any detected
omissions.

### General usage

You can create an ignore matcher using one of two possible ways (see below), but
for both scenarios you'll get back a callable object that works within the
context of a certain directory. These callable objects you can invoke with paths
relative to the context directory, and the return value will indicate whether
the path should be ignored (`true` for ignore, and `false` for allowing it).

The relative paths passed are assumed to have a trailing slash for directory
entries.

## Functions

### evaluator (dir, opts = {})

This creates an ignore matcher for the specified `dir`, which will take into
account any parent ignore files as well as any relevant ignore files in sub
directories. By default the evaluator will consult both `.gitignore` and
`.ignore` files (giving precedence to the latter), but this can be controlled by
specifying `ignore_files` in `opts`. The most important file should be specified
first (default values is `{'.ignore', '.gitignore'}`).

#### Example

Given a directory `/tmp/foo` and the following ignore files:

`/tmp/.gitignore`:

```
*.o
root/bar
```

`/tmp/root/.gitignore`:

```
zed
sub/sandwich
```

`/tmp/root/sub/.gitignore`:

```
!my.o
frob
```

The following snippet shows the expected results:

```moonscript
dir = howl.io.File('/tmp/root')
ignore = howl.util.ignore_file.evaluator dir
ignore 'obj.o' -- => true (from parent ignore file)
ignore 'bar' -- => true (from parent ignore file)
ignore 'zed' -- => true (from root file)
ignore 'sub/sandwich' -- => true (from root ignore file)
ignore 'sub/my.o' -- => false (overriden from sub ignore file)
ignore 'sub/frob' -- => true (from sub ignore file)
ignore 'frob' -- => false (ignored only in sub directory)
```

### ignore_file(file, dir)

Invoking the module directly for a given file returns a matcher for the
specified file only. No parent or sub directory ignore files will be consulted,
only `file`. If `dir` is specified then the matching will be done in the context of
that directory - otherwise the file's parent directory will be used as the
context.
