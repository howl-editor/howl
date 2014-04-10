---
title: howl.config
---

# howl.config

## Overview

Things that are meant to be configurable in Howl are exposed as "configuration
variables". Configuration variables can be set either interactively from within
Howl, using the `set` command, or programmatically from code. To get an overview
of currently available variables, type `set` and press `space` at the readline
to view a list.

Configuration variables can be specified at three different levels in Howl,
in ascending order of priority:

- *Globally*

The value set for the variable is used unless overridden by a mode or buffer
specific setting (the `set` command always sets variables globally).

- *Per mode*

The value is set for a particular mode (e.g. "Lua" or "Ruby"), and is applied
whenever a buffer with that particular mode is active. The value is used unless
overridden by a buffer specific setting, and overrides any global setting.

- *Per buffer*

The value is set for a particular buffer, and is applied whenever that buffer is
active. The value overrides any mode specific or global setting.

As described above, variables can be set on three different levels. No matter
the on what level they're set, they're always set (and accessed) using `config`
objects. For global accesses, you would use `howl.config` (this module). For
mode variables you access variables using the config object on a particular mode
instance, and similarly for buffer variables you use the config object for a
particular buffer.

The following code snippet illustrates the idiomatic ways of setting variables
on different levels:

```lua
howl.config.my_var = 'foo'
howl.mode.by_name('ruby').config.my_var = 'foo'
howl.app:new_buffer().config.my_var = 'foo'
```

_See also_:

- The [spec](../spec/config_spec.html) for config

## Properties

### definitions

A table of all known variables definitions, keyed by the variable name. For more
information about the structure of the definitions, see [define](#define).

## Functions

### define (options)

Defines a new config variable. Options can contain the following fields:

- `name`: The name of the configuration variable (_required_)

- `description`: A description of the configuration variable (_required_)

- `scope`: An optional value specifying the scope of the variable. One of
  `local` and `global`. Local variables are only allowed to be set for a
  [Buffer] or a [mode], whereas a global variable can only be directly on
  the global config.

- `validate`: A function that will be used for validating any values set
  for this variable. Whenever a value is set for the variable, this function
  will be invoked with the new value as sole parameter. The function should
  return true if the value is valid, and false otherwise.

- `convert`: A function that will be used for converting a value into a type
  suitable for the variable. Whenever a value is set for the variable, this function
  will be invoked with the new value as sole parameter, and the return value,
  if not nil, will be used as the value. Keep in mind that variables are set not
  only via code, but also interactively through commands. In the latter case, values
  will invariably be strings.

- `tostring`: A function that will be used for transforming a value into a
string representation suitable for displaying. This would typically be used for
more advanced option types. For symmetry it's recommended that any `convert`
function is able to successfully convert the return value of `tostring` back
into a native representation.

- `options`: A list (table) of valid values for the variable. Any set value will
  be validated to be part of this list (after conversion), if set.

- `type_of`: To simplify defining new variables in Howl, there are a set
  of predefined types you can use that will handle validation, conversion,
  etc. of variable values for you. You use one of these by specifying the
  name of the predefined type here (as a string). Currently predefined
  types are:

  - boolean
  - number
  - string
  - string_list

### get (name)

Gets the global value of the variable named `name`. While getting the value of a
variable using `get` is perfectly fine, note that the idiomatic way of getting
variables values globally is to just to index the config module, like so:

```lua
local val = howl.config.my_variable
```

### local_proxy ()

Returns a new configuration proxy object. A proxy object offers access to all
configuration variables defined in Howl, using simple indexing:

```lua
proxy = howl.config.local_proxy()
proxy.indent -- => 2
```

Assigning to a proxy object only sets the value locally however:

```lua
proxy = howl.config.local_proxy()
proxy.indent = 5
howl.config.indent -- => 2
proxy.indent -- => 5
```

Proxy objects offers one additional feature in addition to the above; the
possibility of chaining to a different configuration object other than the
global howl.config module. Using the `chain_to` method, it's possible to create
hierarchies of configuration objects (as is done in Howl for modes and buffers):

```lua
proxy = howl.config.local_proxy()
next_proxy = howl.config.local_proxy()
next_proxy.chain_to(proxy)
```

In the above example, `proxy` would defer any lookups not set locally to the
global howl.config module, and `next_proxy` would defer any lookups to `proxy`.
Proxies work against the global configuration variable definitions, and respects
any validations, conversions, etc., specified.

### set (name, value)

Globally sets the value of the configuration variable with name `name` to be
`value`. An error is raised for any of the following scenarios:

- There exists no known variable with name `name`
- `value` is not a valid value for the parameter
- The parameter was defined with the scope "local"

Upon a successful change, any listeners are notified. To remove any previously
set value, pass `nil` as `value`. While setting a variable using `set` is
perfectly fine, note that the idiomatic way of setting variables globally is to
just assign to the variable name in the config module, like so:

```lua
howl.config.my_variable = true
```

### watch (name, callback)

Registers a listener for the variable named `name`. `callback`, which must be
callable, will be invoked whenever the specified variable has a new value set.
`callback` will be invoked with three parameters:

*name* - The name of the parameter being set
*value* - The new value of the parameter
*is_local* - A boolean indicating whether the value was set locally or globally.

[Buffer]: buffer.html
[mode]: mode.html
