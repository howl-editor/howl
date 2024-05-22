---
title: howl.io.Process
---

# howl.io.Process

## Overview

The Lua runtime itself only provides rudimentary support for running processes,
in the form of
[os.execute](http://www.lua.org/manual/5.2/manual.html#pdf-os.execute) and
[io.popen](http://www.lua.org/manual/5.2/manual.html#pdf-io.popen). Apart from
not providing any way of more advanced interaction with the process, such as
sending signals, the above both suffer from the flaw of blocking program
execution. In the context of an interactive application, such as Howl, this is
unacceptable is it means the application will be unresponsive while waiting for
command termination or output. The howl.io.Process module provides a way of
launching and interacting with external processses that, while still providing
the appearance and ease of use of a synchronous API, is fully asynchronous and
ensures Howl remains responsive.

_See also_:

- The [spec](../../spec/io/process_spec.html) for Process

## Class Properties

### running

A table containing all currently running processes, keyed by the process pid.

## Properties

### argv

The argument list that was used to launch the process.

### command_line

A string representation of the command run. If the process was created using a
string command (`cmd` was specified as a string), this will be equal to the
passed in command. If the process was created using a argument table, this will
be a space separated string with any arguments containing blanks being quoted
using single quotes.

### exited

True if the process has terminated, normally or not, and false otherwise.

### exited_normally

True if the process terminated normally, i.e. due to an explicit exit or a
return from `main`, and false otherwise. Only available once the process has
exited ([exited](#exited) is true).

### exit_status

The exit status of the process. Only available if the process has exited
normally ([exited_normally](#exited_normally) is true).

### pid

The process id of the process.

### signal

Holds the signal that caused the process to terminate. Only available if the
process was indeed terminated due to a signal ([signalled](#signalled) is true).

### signalled

True if the process was terminated as the result of a signal. Only available
once the process has exited ([exited](#exited) is true).

### signal_name

A string representation of the signal that caused the process to terminate. Only
available if the process was indeed terminated due to a signal
([signalled](#signalled) is true).

### exit_status_string

A string containing a human readable representation of the process exit status.
Only available once the process has exited ([exited](#exited) is true).

### stderr

An [InputStream] instance that can be used for reading the process' error
output. The process must have been created with the `read_stderr` option for
this field to be available.

### stdin

An [OutputStream] instance that can be used for writing to the process' input.
The process must have been created with the `write_stdin` option for this field
to be available.

### stdout

An [InputStream] instance that can be used for reading the process' standard
out. The process must have been created with the `read_stdout` option for this
field to be available.

### successful

True if the process exited normally, with an exit code of zero. Only available
once the process has exited ([exited](#exited) is true).

### working_directory

A [File] instance for the process' working directory.

## Functions

### Process(options)

Launches a new process with the specified options, and returns a Process
instance. `options`, a table, can contain the following fields:

- `cmd`: _[required]_ The command to run. This can be either a string, in which
case it's executed using `/bin/sh` (or using the shell specified by `shell`), or
a table comprising the full command line invocation.

- `read_stdout`: _[optional]_ When specified, a pipe will be opened for the
process' standard out, and the [stdout](#stdout) field will be available for
reading the process' output.

- `read_stderr`: _[optional]_ When specified, a pipe will be opened for the
process' error out, and the [stderr](#stderr) field will be available for
reading the process' error output.

- `write_stdin`: _[optional]_ When specified, a pipe will be opened for the
process' input, and the [stdin](#stdin) field will be available for writing to
the process' input.

- `working_directory`: _[optional]_ The path to set as the process' working
directory.

- `env`: _[optional]_ A table of keys and values that will be used as the
process' environment.

- `shell`: _[optional]_ A string specifying the shell to use for executing the
command. The specified shell will be invoked with the `-c` parameter, with the
command parameters directly following. This parameter is only respected if `cmd`
is a string.

An error will be raised if the specified command could not be started. Otherwise
a process object is returned for the started command.

### open_pipe(cmd, options = {})

Creates a process for `cmd`, setup for piping (enabling reading of both stdout
and stderr). `cmd` can be either a string, in which case it's executed using
`/bin/sh`, or a table comprising the full command line invocation. `options`, a
optional table of options, can contain the following optional fields:

- `stdin`: When specified, the contents of this field will be written as the
process' input before the process is returned.

- `working_directory`: The path to set as the process' working directory.

- `env`: A table of keys and values that will be used as the process'
environment.

- `shell`: _[optional]_ A string specifying the shell to use for executing the
command. The specified shell will be invoked with the `-c` parameter, with the
command parameters directly following. This parameter is only respected if `cmd`
is a string.

An error will be raised if the specified command could not be started, or if an
IO error occurs. Otherwise the function returns the created process object,
which can for instance be used together with [pump](#pump).

Examples of valid invocations:

```moonscript
howl.io.Process.open_pipe 'echo "foo bar"'

howl.io.Process.open_pipe {'sh', '-c', 'echo foo >&2' }

howl.io.Process.open_pipe 'pwd', working_directory: '/bin'

howl.io.Process.open_pipe 'env', env: { foo: 'bar' }

howl.io.Process.open_pipe 'cat', stdin: 'give it back!'
```

### execute(cmd, options = {})

Executes a process for `cmd` and returns the results in one go. This is
basically a convenience wrapper that internally creates a new process using
[open_pipe](#open_pipe) and reads its output using [pump](#pump). Both `cmd` and
`options` are the same as for [pump](#pump) so consult that documentation for
the available options.

An error will be raised if the specified command could not be started, or if an
IO error occurs. Otherwise the function returns three values: The standard
output of the command as a string, the error output of the command as a string,
and the process object representing the terminated process.

Examples:

```moonscript
howl.io.Process.execute 'echo "foo bar"'
-- =>  "foo bar\n", "", <Process>

howl.io.Process.execute {'sh', '-c', 'echo foo >&2' }
-- =>  "", "foo\n", "", <Process>

howl.io.Process.execute 'pwd', working_directory: '/bin'
-- =>  "/bin\n", "", "", <Process>

howl.io.Process.execute 'env', env: { foo: 'bar' }
-- =>  "foo=bar\n", "", "", <Process>

howl.io.Process.execute 'cat', stdin: 'give it back!'
-- =>  "give it back!", "", "", <Process>
```

## Methods

### pump ([on_stdout, on_stderr])

"Pumps" the process for any output. The method will return once the process has
exited. Note that you need to create the process with the corresponding `read_*`
flags in order to read any output - `read_stdout` to capture stdout, and
`read_stderr` to capture stderr.

The `on_stdout` and `on_stderr` handlers, if specified, will be invoked
as soon as any output from the respective stream is available from the process,
receiving as their sole argument the output as a string. As the process output
streams are closed the handlers will be invoked a final time with nil,
signifying end-of-file.

Any of the two handlers (`on_stdout` and `on_stderr`), or both, can be omitted.
In this case any output from the related stream is collected and returned as a
return value from `pump`, with stdout being returned before stderr. For example,
invoking `pump` without arguments for a process opened with the `read_stdout`
and the `read_stderr` flags would collect both stdout and stderr and return
(`stdout`, `stderr`) as the return values.

Example:

```moonscript
p = howl.io.Process cmd: 'echo out; echo err >&2', read_stdout: true, read_stderr: true
p\pump!
-- => "out\n", "err\n"

p = howl.io.Process cmd: 'echo out; echo err >&2', read_stdout: true
p\pump!
-- => "out\n", nil

```

### pump_lines ([on_stdout, on_stderr])

"Pumps" the process for any output, returning any output as individual lines.
Similarly to [pump](#pump) the method reads any output from the process and
returns once the process has exited. Also similarly you need to create the
process with the corresponding `read_*` flags in order to read any output -
`read_stdout` to capture stdout, and `read_stderr` to capture stderr.

The `on_stdout` and `on_stderr` handlers, if specified, will be invoked as soon
as any individual lines from the respective stream is available from the
process, receiving as their sole argument the output as a table of lines.

Any of the two handlers (`on_stdout` and `on_stderr`), or both, can be omitted.
In this case any output from the related stream is collected and returned as a
return value from `pump_lines`, with stdout being returned before stderr. For
example, invoking `pump` without arguments for a process opened with the
`read_stdout` and the `read_stderr` flags would collect both stdout and stderr
and return (`stdout_lines`, `stderr_lines`) as the return values.

Example:

```moonscript
p = howl.io.Process cmd: 'echo "one\ntwo|; echo err >&2', read_stdout: true, read_stderr: true
p\pump!
-- => {'one', 'two'}, {'err'}

p = howl.io.Process cmd: 'echo "one\ntwo"; echo err >&2', read_stdout: true
p\pump!
-- => {'one', 'two'}, nil

```

### send_signal (signal)

Sends `signal` to the process. `signal` can be either a number or a string
representation of the signal, such as `HUP`, `KILL`, etc.

### wait ()

Waits for the process to terminate.

[InputStream]: input_stream.html
[OutputStream]: output_stream.html
[File]: file.html
