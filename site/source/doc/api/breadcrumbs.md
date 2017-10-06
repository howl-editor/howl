---
title: howl.breadcrumbs
---

# howl.breadcrumbs

## Overview

The breadcrumbs module keeps track of previously visited locations within Howl,
and provides functions for remembering a specific location as well as for
navigating forward and backward in the breadcrumb trail.

### Structure of a breadcrumb

Each crumb describes a previously visited location, and has the following
fields:

- `pos`: The position in the buffer or file.

- `file` _(optional)_: The file associated with the location. This is not always
present, as not all buffers have an associated file.

- `buffer_marker` _(optional)_: A table providing information about a buffer
location. This contains two fields:
  - `buffer`: A reference to the buffer
  - `name`: The name of a marker used for tracking the location

As can be seen above, a crumb has a file reference, or a buffer reference via
the `buffer_marker` field, or both at the same time. In the case where a marker
is available that should be used for determining the correct position, as `pos`
could become stale due to subsequent edits.

---

_Related_:

- The `navigate-back` and `navigate-forward` commands can be used in bindings or
from the command line to navigate the crumbs.

## Properties

### location

The current location in the trail. As the user edits this will typically point
to an uninitialized crumb, as it points to the position that will be next used
for storing a crumb using [drop](#drop).

### next

The next crumb in the trail, if any. This will be non-nil only if the user has
navigated back in the breadcrumb trail.

### previous

The previous crumb in the trail, if any, or `nil`.

### trail

The table of breadcrumbs.

## Functions

### clear ()

Clears all current breadcrumbs. After this [location] would be 1, and
[trail] would have a size of 0.

### drop (opts)

Inserts a crumb at the current [location] based on on the value in `opts`, if
provided, or otherwise on the current edit location. `opts` can contain the
following fields:

- `buffer`: A reference to a [Buffer] for the crumb.

- `file`: A reference to a [File] for the crumb. If this isn't provided, but
`buffer` is, then this is deduced from the buffer if possible.

- `pos`: The position of the crumb.

If `opts` is provided, then `pos` must be present, and at least one of `buffer`
and `file`. If `opts` is `nil` then a breadcrumb based on the current editing
location.

### go_back ()

This moves backwards in the breadcrumb trail, if possible. Note that as part of
moving backwards, a new crumb is first inserted at the current location.

### go_forward ()

This moves forward in the breadcrumb trail, if possible. Note that as part of
moving forward, a new crumb is first inserted at the current location.

[location]: #location
[trail]: #trail
[File]: io/file.html
[Buffer]: buffer.html
