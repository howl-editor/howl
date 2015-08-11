-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

glib = require 'ljglibs.glib'

{
  env: setmetatable {}, {
    __index: (variable) => glib.getenv variable
    __newindex: (variable, value) =>
      if value
        glib.setenv variable, value
      else
        glib.unsetenv variable

    __pairs: ->
      env = {var, glib.getenv(var) for var in *glib.listenv!}
      pairs env
  }
}
