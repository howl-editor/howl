---
title: howl.dispatch
---

# howl.dispatch

## Overview

howl.dispatch provides a set of functions for handling and coordinating Lua
coroutines. Coroutines are used in Howl to provide a synchronous API over
asynchronous operations, such as interacting with external processes, waiting
for user input, etc. The primary benefit of the dispatch module is that it
provides an easy to use yielding mechanism, for suspending the currently running
coroutine until a particular event has been triggered.

_See also_:

- The [spec](../spec/dispatch_spec.html) for howl.dispatch

## Functions

### launch (f, ...)

Invokes `f` in a coroutine, with any additional arguments passed to `launch`. If
the coroutine starts correctly, `true` is returned along with the coroutine's
status (e.g. 'running', 'dead'). If an error is encountered upon launching the
coroutine, `false` is returned along with the error message.

### park (description)

Creates and returns a "parking handle", which can be used with [wait],
[resume] and [resume_with_error]. `description` should be a short descriptive
text indicating the nature of the operation to be parked.

### resume (handle, ...)

Resumes the coroutine associated with `handle`, which should be a parking handle
obtained from [park]. Any additional arguments passed will be used as the return
values from corresponding [wait].

### resume_with_error (handle, err, level = 1)

Resumes the coroutine associated with `handle`, which should be a parking handle
obtained from [park]. Resuming with an error means that the corresponding [wait]
will not return normally, but instead raise the error specified in `err`. The
optional `level` parameter allows specifying where in the stack of the waiting
coroutine the error occurred, similar to the level parameter to
[error](http://www.lua.org/manual/5.2/manual.html#pdf-error).

### wait (handle)

Suspends the coroutine from which `wait` is invoked until `handle`, a parking
handle obtained from [park], is resumed from either [resume] or
[resume_with_error].

[wait]: #wait
[resume]: #resume
[resume_with_error]: #resume_with_error
[park]: #park
