---
title: Howl development
---

# Howl development

In this page, we'll introduce Howl development and talk about some things you
need to know when developing for Howl.

## Running Howl for development

First off, you need to make sure that you're building and running Howl directly
from the latest source. Chances are that you're already doing so, but if you
currently run Howl from a binary package you want to clone the [Howl
repo](https://github.com/howl-editor/howl/) and build Howl from there (see the
[instructions here](/getit.html#building-howl-from-source) for more details).
You can keep up with the latest changes for Howl by tracking the `master`
branch. While there's no guarantee that you'll never experience problems while
tracking the latest, the `master` branch is intended to be stable at all times,
and is used as the base branch by the developers themselves on a daily basis.

As mentioned on the previously linked page, once Howl has been built from
source, there is two possible ways one might run it; you can either run it by
installing it and running it from the installed location (`/usr/local/` by
default), or you can run it directly from the checkout directory. When
developing for, and making changes to Howl itself, the easiest option is to run
Howl directly from the checkout directory.

## Rebuilding after changes

Howl has a minimal C core, and has some dependencies written in C as well, all
of which is compiled as you type `make`. Nearly all of Howl is actually written
in Moonscript (and some Lua) however. While neither Moonscript or Lua is
compiled in the traditional sense, for Howl they are both compiled down to
LuaJIT byte code. This is done for performance reasons, as we are mindful of the
startup time for Howl.

While the use of byte code does not present a problem for end users who simply
install Howl once, it must be accounted for when making changes, or when trying
out others' changes. The most straight forward way of making sure that byte
code, etc., is updated after sources have changed is to remake again (i.e. `cd
src && make`). While this will always work (and is required for the rare changes
to the C core), it's also slow. For the typical workflow where you edit a source
file and save it, only the byte code needs to be updated. Fortunately, Howl
automatically updates this for you when it can, so it's something that you
shouldn't have to consider. This will work out of the box as long as you run
Howl directly from within the checkout directory - any Moonscript or Lua files
below the checkout directoy will have their byte code versions updated
automatically as you save them.

While the recommended way of developing for Howl is to simply run it from within
the checkout directory, it's also possible to explicitly instruct Howl to update
byte code for files within another directory. In this scenario one might for
instance run Howl from an installed stable version, and do development in the
ordinary checkout directory. Since Howl cannot reasonably be expected to try and
save byte code for arbitrary files scattered all over your file system, you have
to specify the Howl source directory explicitly in this case. The configuration
variable `howl_src_dir` can be used for this. For instance, you can set it like
this in your Howl configuration (example using `~/.howl/init.moon`):

```moonscript
{:config} = howl
{:File} = howl.io

config.howl_src_dir = File.expand_path('~/code/howl')
```

## Running the specs (tests)

Howl has a whole lot of specs that verify different aspects of its behaviour.
These are written using the [busted](http://olivinelabs.com/busted/) testing
framework (the stable 1.* version, not the unstable pre-2.* version). Starting
with the 0.5 release, Howl bundles all dependencies needed for running the
specs, so you don't have to worry about manually installing `busted`, or
`luarocks`, etc. Instead, simply run the `howl-spec` script (located in the
`bin/` directory), specifying the spec or specs you want to run. You can either
specify individual files to run, or specify the path to a directory, in which
case all specs below that directory will be run. Note that you'll need to run
the `howl-spec` script from within the project root, like so:

```shell
[howl-dir] $ ./bin/howl-spec <path-to-file-or-directory>
```

Since running specs manually can get quite tedious, e.g. when doing test driven
development, you can run a watcher of some sort that will automatically run the
right specs as files are changed. Howl ships with a ready-made Spookfile that
can be used with the [spook](https://github.com/johnae/spook) utility (a Lua
based file watcher). If you install spook, then simply run it in the project
root in order to run specs as files are changed.
