---
title: howl.signal
---

# howl.signal

## Overview

Signals provide a way of sending and receiving notifications about various
events that happens within Howl. For example, there are signals emitted whenever
text is added or deleted in a buffer, or a key is pressed in Howl, etc. By
"connecting" a handler for signal, you can easily hook into the ordinary
workings to add your own additional functionality. Signals are defined by their
name, and each signal can provide additional information about the event as
parameters. Each signal can have multiple handlers connected at a given time,
which will all be invoked, provided a handler does not explicitly halt the
processing (see [emit](#emit) for more information).

To view the list of currently registered signals within Howl as well as
information about the parameters you can use the `describe-signal` command.

_See also_:

- The [spec](../spec/signal_spec.html) for signal

## Properties

### .abort

A sentinel value used for causing an early exit during signal dispatch (see
[emit](#emit) for more information).

### .all

This is a table of all currently defined signals within Howl, keyed by their
name. The value associated with each key is the  signal information as passed to
[register](#register).

## Functions

### connect (name, handler [, index])

Connects `handler` to the signal specified by `name`. The optional `index`
argument specifies where in the handler list the handler should be placed. All
handlers for a specific signal are stored in a list, and the index specifies the
order in which they are invoked whenever a signal is emitted, where the handler
with index 1 is invoked first, followed by handlers with greater indices.

An error is raised when trying to connect a handler for a signal that has not
been registered.

### disconnect (name, handler)

Disconnects `handler` from the signal specified by `name`.

### emit (name, parameters)

Emits the signal specified by `name`, along with any optional parameters
contained in `parameters`. `parameters`, if specified, should be a table with
keys matching those of the parameters specified for [register](#register). An
error is raised when trying to emit a signal that has not been registered.

When a signal is emitted each connected handler is invoked in turn, with
`parameters` as the sole argument. Should any handler return `signal.abort`, the
processing is halted and `emit` in turn returns `signal.abort`. Otherwise,
`false` is returned. Any error triggered in a signal handler is logged, and
processing continues.

### register (name, options)

Registers the signal specified in `name`, with the options specified in
`options`. `options` can contain the following fields:

- `description`: A textual description of what the signal is for (*required*)

*Example of how to register a signal*:

```moonscript
signal.register 'mode-registered',
  description: 'Signaled right after a mode was registered',
  parameters:
    name: 'The name of the mode'
```

### unregister (name)

Unregisters the signal specified by `name`.
