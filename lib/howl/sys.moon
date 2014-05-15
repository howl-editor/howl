-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

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
