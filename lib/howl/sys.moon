-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

glib = require 'ljglibs.glib'
C = require('ffi').C

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
  path = env['PATH']

  for dir in path\gmatch "[^:]+"
    exe = howl.io.File(dir) / name
    if exe.exists and not exe.is_directory
      return exe.path


time = -> glib.get_real_time! / 1000000

platform = {}

platform.load_font_dir = (font_dir) ->
  if jit.os == 'Windows'
    require 'howl.cdefs.windows'
    fonts = howl.io.File(font_dir).children
    for font in *fonts
      loaded = C.AddFontResourceExA font.path, C.fr_private, nil
      if loaded == 0
        io.stderr\write "failed to load font #{font.path}\n"
        io.stderr\flush!
  else
    require 'howl.cdefs.fontconfig'
    C.FcConfigAppFontAddDir nil, font_dir

platform.tmpname = ->
  -- os.tmpname is broken on Windows and returns a filename prefixed with \.
  -- This causes a lot of "Access denied"-related errors.
  filename = assert os.tmpname!
  -- Remove the prefix \.
  filename = filename\sub 2 if jit.os == 'Windows'
  filename

platform.fd_to_stream = (win_type, unix_type, fd) ->
  if jit.os == 'Windows'
    win_type C._get_osfhandle fd
  else
    unix_type fd

platform.default_shell = ->
  if jit.os == 'Windows'
    if howl.sys.env.MSYSCON
      -- Running under MSYS2.
      "#{env.WD}sh.exe"
    else
      "#{env.SYSTEMROOT}\\System32\\cmd.exe"
  else
    '/bin/sh'

win_signals = {[tonumber C.sig_KILL]: true, [tonumber C.sig_INT]: true}
platform.send_signal = (pid, signal) ->
  if jit.os == 'Windows'
    error "Signal #{signal} is not supported on Windows" unless win_signals[signal]
    -- On Bash, when a process exits due to a signal, it's exit code is
    -- 128+{signal code}. Since killing a process like that doesn't
    -- necessarily work on Windows, this emulates that exit code.
    C.TerminateProcess(pid, 128+signal)
  else
    C.kill(pid, signal)

{
  :env,
  :find_executable
  :time,
  :platform
  info: {
    os: jit.os\lower!
  }
}
