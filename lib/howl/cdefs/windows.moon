-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'

ffi.cdef [[
  typedef void* HANDLE;
  typedef int DWORD;

  DWORD GetProcessId(HANDLE process);
  HANDLE _get_osfhandle(int fd);
  BOOL TerminateProcess(HANDLE process, unsigned int exitcode);
]]
