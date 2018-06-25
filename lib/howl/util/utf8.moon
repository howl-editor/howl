-- Copyright 2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
const_char_p = ffi.typeof('const unsigned char *')
{:max} = math
ffi_copy, ffi_string = ffi.copy, ffi.string

SEQ_LENS = ffi.new 'const int[256]', {
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
  0,0,0,0,0,0,0,0,0,0,0,0,-1,-1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
  2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,-1,-1,-1,-1,
  -1,-1,-1,-1,-1,-1,-1,
}

REPLACEMENT_CHARACTER = "\xEF\xBF\xBD"
REPLACEMENT_SIZE = #REPLACEMENT_CHARACTER

char_arr = ffi.typeof 'char [?]'
uint_arr = ffi.typeof 'unsigned int [?]'

get_warts = (s, len = #s) ->
  src = const_char_p s
  w_size = 0
  warts = nil
  w_idx = 0
  conts = 0
  seq_start = nil
  i = 0

  mark = ->
    if w_idx >= w_size - 2
      old = warts
      w_size = max 8192, w_size * 2
      warts = uint_arr w_size
      if old
        ffi_copy warts, old, w_idx * ffi.sizeof('unsigned int')

    pos = seq_start or i
    warts[w_idx] = pos
    w_idx += 1
    i = pos
    seq_start = nil
    conts = 0

  while i < len
    b = src[i]
    if b >= 128 -- non-ascii
      if b < 192 -- continuation byte
        if conts > 0
          conts -= 1 -- ok continuation
          if conts == 0
            seq_start = nil -- end of seq
        else
          mark! -- unexpected continuation byte
      else
        -- should be a sequence start
        s_len = SEQ_LENS[b]
        if s_len < 0
          mark! -- no, an illegal value
        else
          if conts > 0
            mark! -- in the middle of seq already
          else
            -- new seq starting
            seq_start = i
            conts = s_len - 1
    else -- ascii
      if conts > 0
        mark! -- expected continuation byte instead of ascii
      elseif b == 0
        mark! -- zero byte

    i += 1

  if seq_start -- broken at end
    mark!

  size_delta = w_idx * (#REPLACEMENT_CHARACTER - 1)
  nlen = len + size_delta + 1 -- additional size for \0
  warts, w_idx, nlen

clean = (s, len = #s) ->
  src = const_char_p s
  warts, wart_count, nlen = get_warts s, len

  if wart_count == 0
    return src, len, 0

  -- create new valid string
  dest = char_arr nlen
  src_idx = 0
  dest_idx = 0

  for i = 0, wart_count - 1
    at = warts[i]
    diff = at - src_idx
    if diff > 0 -- copy any content up until the wart
      ffi_copy dest + dest_idx, src + src_idx, diff
      dest_idx += diff

    -- the replacement character
    ffi_copy dest + dest_idx, REPLACEMENT_CHARACTER, REPLACEMENT_SIZE
    dest_idx += REPLACEMENT_SIZE
    src_idx = at + 1

  diff = len - src_idx
  if diff > 0 -- copy any content up until the end
    ffi_copy dest + dest_idx, src + src_idx, diff

  dest, nlen - 1, wart_count

clean_string = (s, len = #s) ->
  ptr, len, wart_count = clean s, len
  return s, 0 unless wart_count != 0
  ffi_string(ptr, len), wart_count

is_valid = (s, len = #s) ->
  _, wart_count, _ = get_warts const_char_p(s), len
  wart_count != 0

:clean, :clean_string, :is_valid
