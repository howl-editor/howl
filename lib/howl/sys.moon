-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

glib = require 'ljglibs.glib'
{:File} = howl.io

env = setmetatable {}, {
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

find_executable = (name) ->
  return File(name).exists if File.is_absolute(name)

  path = env['PATH']

  for dir in path\gmatch "[^:]+"
    exe = howl.io.File(dir) / name
    if exe.exists and not exe.is_directory
      return exe.path


time = -> glib.get_real_time! / 1000000

{
  :env,
  :find_executable
  :time,
  info: {
    os: jit.os\lower!
  }
}
