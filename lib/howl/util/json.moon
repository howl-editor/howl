-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- JSON for files that people read, and might edit: values are encoded pretty
-- printed with sorted keys, so the same value always gives the same text.

lunajson = require 'lunajson'
{:concat, :sort} = table
append = table.insert

format_number = (n) ->
  if n != n or n == math.huge or n == -math.huge
    error "Cannot encode #{n} as JSON", 0

  s = string.format '%.14g', n
  s = string.format('%.17g', n) if tonumber(s) != n
  s

-- whether t is a non-empty list, possibly with holes, to encode as an array
is_array = (t) ->
  n = #t
  return false if n == 0
  for k in pairs t
    return false unless type(k) == 'number' and k >= 1 and k <= n and k % 1 == 0
  true

local encode_value

encode_table = (t, indent, seen, out) ->
  error 'Cannot encode a table containing itself as JSON', 0 if seen[t]
  seen[t] = true
  inner = indent .. '  '

  if is_array t
    append out, '['
    for i = 1, #t
      append out, (i > 1 and ',\n' or '\n') .. inner
      encode_value t[i], inner, seen, out
    append out, "\n#{indent}]"
  else
    keys = {}
    for k in pairs t
      unless type(k) == 'string'
        error "Cannot encode the #{type k} key '#{k}' as JSON", 0
      append keys, k

    if #keys == 0
      append out, '{}'
    else
      sort keys
      append out, '{'
      for i, k in ipairs keys
        append out, (i > 1 and ',\n' or '\n') .. inner .. lunajson.encode(k) .. ': '
        encode_value t[k], inner, seen, out
      append out, "\n#{indent}}"

  seen[t] = nil

encode_value = (v, indent, seen, out) ->
  switch type v
    when 'table' then encode_table v, indent, seen, out
    when 'number' then append out, format_number(v)
    when 'string', 'boolean' then append out, lunajson.encode(v)
    when 'nil' then append out, 'null'
    else error "Cannot encode a #{type v} as JSON", 0

-- returns value as JSON text, without a trailing newline. Empty tables are
-- encoded as `{}`.
encode = (value) ->
  out = {}
  encode_value value, '', {}, out
  concat out

-- returns the value of the JSON text, where `null` is nil
decode = (text) ->
  error "Expected a string to decode, got #{type text}", 2 unless type(text) == 'string'
  status, ret = pcall lunajson.decode, text
  unless status
    error tostring(ret)\match('parse error.*') or ret, 0
  ret

:encode, :decode
