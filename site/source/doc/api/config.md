---
title: howl.config
---

# howl.config

## Overview

Things that are meant to be configurable in Howl are exposed as "configuration
variables". An example configuration variable is `font_size`, which sets the
size of the main font.

Configuration variables are set either interactively from within Howl, using the
`set` command, or programmatically from code. To get an overview of currently
available variables, open the command line, type `set` and press `space` - this
shows a list of all variables.

Values for configuration variables can be specified at multiple levels, called
*scopes*, and at multiple *layers* within each scope. These are described below.

### Scopes

The *scope* is a path within a hierarchical namespace. An example of a scope is
`'file/home/user/my_dir'` which represents the file path  `/home/user/my_dir`.
Some common scopes are:

- **Global scope**

  The global scope is represented as the empty string `''` and the value is used
  if no specific value is found at any nested scope. The `set` command always
  sets variables at the global scope.

- **File path scope**

  File path scopes are used to specify configuration for specific files
  directories. A file path scope starts with `'file/'`, e.g.
  `'file/home/user/folder'`, and the value applies to all files at or below the
  specified path.

  This value overrides any value set by a parent scope.

- **Unsaved file scope (buffer scope)**

  Unsaved file scopes are used to specify configuraiton for buffers that are not
  associated with any file. These scopes start with `'buffer'`, e.g.
  `'buffer/1234'`, and the value applies to the specific buffer only.

  The `set-for-buffer` command sets variables at the file or buffer scope.

### Layers

Within each scope, multiple layers are available for configuration. By default,
when a value is specified for a scope, it is set for the `default` layer within
that scope. However, a value may also be set for another layer in the same
scope, for instance it may be set for the `'mode:moonscript'` layer. This is
used to define values for specific a buffer [mode]. Layer names are not abitrary
tags but are a predefined set of string tags and the same set of layers is
available at *all* scopes.

Within each scope, the layer specific value applies. If the requested layer
value does not exist, the `default` layer value applies.

The `set-for-mode` command sets the mode specific layer at the global scope.

### Evaluation

The evaluation of a configuration value works as follows:

  - scopes are inspected most specific to least specific
  - within each scope the specified layer is checked before falling back to the `default` layer.

Consider an example - evaluation of the configuration variable, say `font_size`,
for the file `/home/user/my_file.moon` in `moonscript` mode. The following
configuration values are checked, in order, and the first value found is
returned:

```
 1. scope='file/home/user/my_file.moon', layer='mode:moonscript'
 2. scope='file/home/user/my_file.moon', layer='default'

 3. scope='file/home/user', layer='mode:moonscript'
 4. scope='file/home/user', layer='default'

 5. scope='file/home', layer='mode:moonscript'
 6. scope='file/home', layer='default'

 7. scope='file', layer='mode:moonscript'
 8. scope='file', layer='default'

 9. scope='', layer='mode:moonscript'
10. scope='', layer='default'
```


### API

The primitive API consists of [`get()`](#get) and [`set`](#set) calls which
accept scope and layer as additional parameters. However, the following code
snippet illustrates the idiomatic ways of setting variables globally, for a
mode, and for a specific buffer only:

```lua
howl.config.my_var = 'foo'
howl.mode.by_name('ruby').config.my_var = 'foo'
howl.app:new_buffer().config.my_var = 'foo'
```

Note that internally the values are organized within scopes and layers, but this
convenient API is available on [buffer] and [mode] objects. [Proxy](#proxy)
objects, described below are used to build the convenience API.

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

- `scope`: An optional value that specifies what scopes are valid for this
  config variable. Note that this parameter does not specify a scope directly,
  but instead specifies one of the following values:

  - `"local"` - variable can be set for any scope
  - `"global"` - variable can be set for the global scope only

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

### get (name, scope, layer)

Gets the global value of the variable named `name` for the scope `scope` and
layer `layer`. While getting the value of a variable using `get` is perfectly
fine, note that the idiomatic way of getting variables values globally is to
just index the config module, like so:

```lua
local val = howl.config.my_variable
```

The [Evaluation](#Evaluation) section above describes how the value is computed.

### proxy (scope, write_layer='default', read_layer)

Returns a new configuration proxy object, which offers a convenient API to get
and set values for a specific scope and layer. A proxy object offers access to
all configuration variables, using simple indexing:

```lua
proxy = howl.config.proxy('file/path/to/my_file')
proxy.indent -- => 2
```

Assigning to a proxy object only sets the value for the specified scope:

```lua
proxy = howl.config.proxy('file/path/to/my_file')
proxy.indent = 5
howl.config.indent -- => 2
proxy.indent -- => 5
```

Getting and setting values use the default layer, when neither `write_layer` nor
`read_layer` are specified. When `write_layer` is specified, that layer is used
when getting and setting values. When `read_layer` is also specified, that layer
is used when getting values only.

Note that `proxy` objects are used to provide the convenient config API for
[buffer] and [mode] objects, as described in [API](#API) above.

### set (name, value, scope='', layer='default')

Sets the value of the configuration variable with name `name`, for scope `scope`
and layer `layer` to be `value`. An error is raised for any of the following
scenarios:

- There exists no known variable with name `name`
- `value` is not a valid value for the parameter
- The scope is `''` (i.e. global) but the parameter is defined as 'local'
- The scope is not global, but the parameter is defined as 'global'

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

[buffer]: buffer.html
[mode]: mode.html
