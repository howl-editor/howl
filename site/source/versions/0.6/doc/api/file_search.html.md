---
title: howl.file_search
---

# howl.file_search

## Overview

The file_search module offers easy to use support for performing searches in
files. It ships with built-in support for three file search backends (simply
referred to "searchers") but offers the ability to easily register additional
ones if so desired.

Apart from performing the actual searches the module also provides support for
intelligent sorting of the results. The added intelligence compared to the basic
search tools comes from exploiting the knowledge of the current context which is
available in a editing context but not for generic tools.

### Searchers

Searches are registered using the [register_searcher] function, and can be
unregistered using its companion [unregister_searcher]. The searches itself is a
simple table which must provide three fields:

- `name`: The name of the searcher.
- `description`: The description of the searcher.
- `handler`: The handler invoked to perform the search.

#### Search handlers

Search handlers have the following signature:

```
handler(directory, search, opts)
```

I.e. they are invoked with three arguments; `directory` is a [File] instance
specifying the directory in which to perform the search. `search` is a string
containing the actual string to search for. Finally, `opts` is table with the
following possible options:

* `max_message_length`: Specifies the maximum length of messages allowed for
message in search results (see below for more information about search results).

* `whole_word`: Whether the search should be performed for "whole words" only,
or whether sub string matches should be allowed.

The handler can return three different types of return values: First, it can
return a string, in which case it's interpreted as an external search command to
run. The command will be run and its output will be parsed for search results.
Second, it can return a [Process] instance. Here as well the process will be run
and its output will be parsed for search results. Third, the handler can perform
the search in some way of its own design and return the search results directly
in a table.

For handlers performing their own searches it's well to note that care has to be
taken not block the application while performing the search. If needed, the
[activities] module can be used to allow the user feedback and optionally a way
of cancelling the search.

The results should be returned as a table, containing one or more search hit
tables. Each search hit table must contain the following members:

- `path`: The path of the matching file, relative to the search directory of the
search.

- `line_nr`: The line number of the search hit.

- `message`: The search hit message. This is typically the matching line in a
file, or an excerpt thereof.

While not required, if at all possible the search hit should also include the
numeric column of the matching text via the `column` member. This should be
reported using byte offsets.

## Properties

### .searchers

A table of available searchers, keyed by name.

## Functions

### register_searcher (searcher)

Registers the searcher `searcher`. The following fields must be specified for a
searcher:

- `name`: The name of the searcher.
- `description`: The description of the searcher.
- `handler`: The handler invoked to perform the search.

See the section [Searchers](#searchers) for more information about search
handlers.

### search(directory, term, opts = {})

Performs a search in `directory` for the search string in `term`. `opts`, if
specified, can contain the following fields:

- `searcher`: Specifies the searcher to use when searching. Can be either a
string, in which case the corresponding registered searcher is used, or a
searcher table.

- `whole_word` Specifies whether the search should match whole words only, or
whether sub string matches should be returned.

The function returns two values, a table of search results and the actual
searched used for the search. Each search hit contains at least the following
fields:

- `path`: The path of the matching file, relative to the search directory of the
search.

- `line_nr`: The line number of the search hit.

- `message`: The search hit message. This is typically the matching line in a
file, or an excerpt thereof.

Search hits can also optionally contain the following fields:

- `column`: The numeric column of the matching text via the `column` member,
reported as a byte offset.

### sort (matches, directory, term [, context])

Sorts the search hits provided in `matches`. `directory` should be a [File]
pointing to the directory where the search was performed and `term` the search
string. The optional `context` argument is a [BufferContext] instance indicating
the context from which the search was performed. If provided, search hits will
be ranked according to their relevance to the given position.

### unregister_searcher(name)

Unregisters the searcher with name `name`.

[register_searcher]: #register_searcher
[unregister_searcher]: #unregister_searcher
[File]: io/file.html
[Process]: io/process.html
[activities]: activities.html
[BufferContext]: buffer_context.html
