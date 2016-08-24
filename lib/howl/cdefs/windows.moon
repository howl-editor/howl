-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'

ffi.cdef [[
  typedef void* HANDLE;
  typedef void* PVOID;
  typedef int DWORD;
  typedef int BOOL;
  typedef char* LPTSTR;
  typedef const char* LPCTSTR;

  DWORD GetProcessId(HANDLE process);
  HANDLE _get_osfhandle(int fd);
  BOOL TerminateProcess(HANDLE process, unsigned int exitcode);
  int AddFontResourceExA(LPCTSTR lpszFilename, DWORD fl, PVOID pdv);
  DWORD GetTempPathA(DWORD buflen, LPTSTR buf);

  int fr_private, max_path;
]]
