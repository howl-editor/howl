-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import P, B, S, Cp, Cc, Ct, Cmt, Cg, Cb from lpeg
import pairs, setfenv, setmetatable, type, print, tostring from _G
l = lpeg.locale!
import space, alpha from l

cur_line_indent = (subject, pos) ->
  ws = 0
  for i = pos, 1, -1
    c = subject[i]
    if i != pos and c\match '[\n\r]+' then return ws
    elseif c\match '%s+' then  ws += 1
    else ws = 0
  ws

indented_block_end = (subject, pos) ->
  cur_indent = cur_line_indent subject, pos - 1
  pattern = r"\\R()\\s{0,#{cur_indent}}\\S"
  block_end = subject\umatch pattern, pos
  block_end and block_end or #subject + 1

paired_end = (subject, pos, delimeter, escape) ->
  while pos <= #subject
    start_pos, end_pos = subject\find delimeter, pos, true
    return #subject + 1 unless start_pos

    unless escape and subject\sub(start_pos - #escape, start_pos - 1) == escape
      return end_pos + 1

    pos = end_pos + 1

find_strings = (subject, pos, escape, ...) ->
  local start_pos
  for match in *{...}
    search_pos = pos
    while search_pos
      found_at, search_pos = subject\find match, search_pos, true
      if found_at
        if not escape or subject\sub(found_at - #escape, found_at - 1) != escape
          start_pos = math.min(found_at, start_pos or math.huge)
          break

        search_pos += 1

  start_pos or #subject + 1

skip_if_next = (subject, pos, token) ->
  if subject\sub(pos, pos + #token - 1) == token
    return pos + #token

-- START lexer environment --

lexer = {}

-- import lpeg operations and locale patterns
lexer[k] = v for k,v in pairs lpeg when k\match '^%u'
lpeg.locale lexer

setfenv 1, lexer
export *

capture = (style, pattern) ->
  Cp! * pattern * Cc(style) * Cp!

any = (...) ->
  args = {...}
  args = args[1] if type(args[1]) == 'table'
  arg_p = P args[1]
  arg_p += args[i] for i = 2, #args
  arg_p

sequence = (...) ->
  args = {...}
  args = args[1] if type(args[1]) == 'table'
  arg_p = P args[1]
  arg_p *= args[i] for i = 2, #args
  arg_p

word = (args) ->
  word_char = alpha + '_'
  (-B(1) + B(-word_char)) * any(args) * -word_char

scan_until = (stop_p, escape_p) ->
  stop_p = P(stop_p)
  skip = (-stop_p * 1)
  skip = (P(escape_p) * 1) + skip if escape_p
  skip^0 * (#stop_p + P(-1))

scan_to = (stop_p, escape_p) ->
  stop_p = P(stop_p)
  scan_until(stop_p, escape_p) * stop_p^-1

scan_through_indented = ->
  Cmt P(true), indented_block_end

scan_until_capture = (name, escape, ...) ->
  p = Cc(escape) * Cb(name)
  p *= Cc(halt) for halt in *{...}
  Cmt p, find_strings

match_until = (stop_p, p) ->
  stop_p = P(stop_p)
  p = P(p)
  scan = (-stop_p * p)
  scan^0 * (#stop_p + P(-1))

span = (start_p, stop_p, escape_p) ->
  start_p * scan_to stop_p, escape_p

paired = (p, escape = nil, pair_style = nil, content_style = nil) ->
  if pair_style
    sequence {
      capture(pair_style, Cg(p, '_pair_del')),
      capture(content_style, scan_until_capture('_pair_del', escape)),
      capture(pair_style, p),
    }
  else
    p = C(p) * Cc(escape) if escape
    Cmt p, paired_end

match_back = (name) ->
  Cmt Cb(name), skip_if_next

eol = S('\n\r')^1

complement = (p) ->
  P(1) - p

new = (definition) ->
  setfenv definition, lexer
  pattern = definition!
  setmetatable {}, __call: (_, text) ->
    match = any {
      pattern,
      capture('whitespace', space^1),
      P 1
    }
    p = Ct match^0
    p\match text

setmetatable lexer, __call: (t, ...) -> new ...

return lexer
