---
title: Support for running external commands
location: Stockholm, Sweden
---

Beginning with the upcoming 0.3 release of Howl, it's now possible to launch and
interact with external commands from within Howl.

READMORE

The new functionality is exposed via the new
[io.Process API](../doc/api/io/process.html), as well as two new commands,
`exec` and `buffer-exec`. The API allows for a fine level of control over any
spawned process, and let's you easily develop your own Howl customizations
involving sub processes, while the two new commands offer a simple and powerful
way of launching one-off commands.

This post will actually not expound further on the added support, since there
are other resources that do a better job of it:

- The [manual](../doc/manual/running_commands.html) has been updated with a new
chapter that describes the two new commands

- The aforementioned [API](../doc/api/io/process.html) documents the
functionality available to you for use in your own code.

- A [demo video](http://vimeo.com/111560817) (embedded below) has been prepared
that gives you quick tour of the new features!

<iframe src="//player.vimeo.com/video/111560817?byline=0&amp;portrait=0" width="500" height="281" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

[Howl - Running external commands](http://vimeo.com/111560817).

Again, this functionality will be part of the upcoming 0.3 release, but if you
want to try this out right away this is all available in the unreleased
[master branch](https://github.com/nilnor/howl/commits/master).

Have fun!

