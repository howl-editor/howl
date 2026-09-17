---
title: howl.activities
---

# howl.activities

The activities module keeps track of long running operations with Howl, that
either is or should appear to be blocking in nature.

While most operations within Howl are fast enough that any blocking is at most a
nuisance, some things can be slow enough that it's not reasonable to perform
them in a blocking manner without any feedback to the user (apart from an
unresponsive editor). Alternatively, some operations can be slow but
non-blocking (e.g. using some of Howl's asynchronous APIs), and could by mistake
allow the user to work before the result of a needed operation is ready.

Using the `run` or `run_process` functions available from the activities module,
code can run designated blocks of code as activities. An activity is in its most
basic form simply a named part of code, with an associated dynamic status, whose
execution is supervised by the activities module. If the execution of the
activity has not completed within a specific interval the user is alerted to the
ongoing operation via a popup at the bottom at the current window, providing
insight into what is being done and optionally any progress.

_A note about Howl's execution model_:

Howl is a single threaded application. It still allows multiple concurrent
operations, such as running processes, etc., via the use of asynchronous IO.
This is not something that is always readily apparant since Howl's APIs hides
this fact and provides the illusion of a blocking execution, but it's necessary
to know that at most one trail of execution is taking place at any given time.
With regards to activities the implication is that any activity that uses an API
which ends up doing asynchronous IO works well out of the box with the
activities module, as it's able to update the user interface properly. However,
for other activities such as activities heavy in data manipulation or
computation explicit action needs to be taken to ensure that the activities
module can properly run. This can be done either by using the [yield] function,
or as a last resort specifying the `preempt` flag to [run] or
[run_process].

## Properties

### nr

The number of currently running activities.

### nr_visible

The number of currently running activities with visible status windows.

## Functions

### run (options, f)

Runs an activity function `f`, described by `options`.

`options` can contain any of the following keys:

- *title*: (required) The title of the activity.

- *status*: (required) A status function. This will be invoked dynamically as
necessary in order to get an updated status to show to the user.

- *cancel*: (optional) Providing this function marks an activity as cancellable.
If the user chooses to cancel the operation this function will be called. Note
that the function might possibly be called more than once.

- *keymap*: (optional) An extra keymap for the activity that will be accessible
when the activity is being visibly displayed.

- *preempt*: (optional) This is available as a last fallback resort for
activities which would otherwise run uninterruptibly, and which can not for some
reason be instrumented using [yield]. Avoid using this if at all possible since
it has a very large impact on performance.

#### Example use (Moonscript):

```moon
files_found = 0
cancel = false

activities.run {
  title: "Scanning '#{directory}'"
  status: -> "Reading files.. (#{files_found} files read)"
  cancel: -> cancel = true
}, ->
  directory\find
    on_enter: (dir, files) ->
      files_found = #files
      return 'break' if cancel
```

### run_process (options, f)

Runs a process `p` as an activity, described by `options`. `options` can contain
the keys `title`, `status` and `keymap`, which work the same way as for [run].
Note however that `status` is optional when calling this function - if not
provided a generic status function will be provided based on the running
process.

In addition, `options` can contain the following keys:

- *on_output*: (optional) A handler function that process output as it becomes
available. Depending on the `read_lines` flag this function will be invoked zero
or more time with either a table of lines, or a string containing the output. If
this is not specified the process' error output is returned as the first return
value.

- *on_error*: (optional) A handler function that process error output as it
becomes available. Depending on the `read_lines` flag this function will be
invoked zero or more time with either a table of lines, or a string containing
the output. If this is not specified the process' error output is returned as
the second return value.

- *read_lines*: (optional) Specifies whether the process output should be
returned or passed as tables of parsed lines or simply as text. Defaults to
`false`.

The default behaviour of this function is to return the process' output as its
return values, as table of lines or as text, depending on whether the
`read_lines` option was passed or not. Should any output handler be specified
(`on_output` or `on_error`) the corresponding return value will be empty.

### yield ()

Some activities will unless checked run uninterrupted, not providing the
activities module with any chance of kicking in. In these cases the offending
code can be instrumented with `yield` calls at suitable intervals.

#### Example use (Moonscript):

```moon
cancel = false
activities.run {
  title: "Juggernaut",
  status: -> "I love iterating!",
  cancel: -> cancel = true
}, ->
  entries = load_100k_entries!
  return for i = 1, #entries
    break if cancel
    activities.yield! if i % 1000 == 0
    map_entry entries[i]
```

[run]: #run
[run_process]: #run_process
[yield]: #yield
