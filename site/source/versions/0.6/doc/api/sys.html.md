---
title: howl.sys
---

# howl.sys

The howl.sys module provides some convinient accessors to system information.

## Properties

### env

A table containing the environment variables for Howl. You can use this retrieve
the values for certain environment variables, assign to it to change environment
variables and iterate over the environment variables using
[pairs](http://www.lua.org/manual/5.2/manual.html#pdf-pairs).

Examples:

```lua
print(env.HOME) -- => "/home/nino"

-- Re-assign HOME
env.HOME = '/other/home'
print(env.HOME) -- => "/other/home"

-- unset HOME
env.HOME = nil
print(env.HOME) -- => nil

-- iterate over and print all variables
for k,v in pairs(env) do
  print(k .. '=' .. v)
end
```

## Functions

### time

Returns the current system time as seconds since the [POSIX
epoch](https://en.wikipedia.org/wiki/Unix_time). The returned float value has
microsecond resolution.
