ffi = require 'ffi'

tonumber = tonumber
C = ffi.C

char_offset = (ptr, byte_offset) =>
  offset_ptr = ptr + byte_offset
  tonumber C.g_utf8_pointer_to_offset(ptr, offset_ptr)

byte_offset = (ptr, char_offset) =>
  next_ptr = C.g_utf8_offset_to_pointer(ptr, char_offset)
  tonumber next_ptr - ptr

-> :char_offset, :byte_offset
