-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import P, B, S, Cp, Cc, Ct, Cmt from lpeg
import pairs, setfenv, setmetatable, type from _G
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

span = (start_p, stop_p, escape_p) ->
  start_p * scan_to stop_p, escape_p

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