-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'

ffi.cdef [[
  typedef struct {} FcConfig;
  int FcConfigAppFontAddDir(FcConfig *config, const char *dir);
]]
