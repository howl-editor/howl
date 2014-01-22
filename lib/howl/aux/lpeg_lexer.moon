-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import mode from howl
import P, B, S, Cp, Cc, Ct, Cmt, Cg, Cb from lpeg
import pairs, setfenv, setmetatable, type, print, tostring from _G
l = lpeg.locale!
import space, alpha from l
lpeg_type = lpeg.type
unpack, append, tinsert = table.unpack, table.insert, table.insert

eol_p = P'\n' + P'\r\n' + P'\r'
blank_p = S(' \t')

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

match_if_equal = (subject, pos, value1, value2) ->
  return pos if value1 == value2

sub_lex_capture_start = (sub_text, sub_start_pos, cur_pos) ->
  trailing_line_p = blank_p^0 * eol_p
  content_start = trailing_line_p\match sub_text
  capture = { cur_pos }

  if content_start
    new_start_pos = sub_start_pos + content_start - 1
    capture = {
      cur_pos,
      sub_start_pos,
      'default:whitespace',
      new_start_pos
    }
    sub_text = sub_text\sub content_start
    sub_start_pos = new_start_pos

  sub_text, sub_start_pos, capture

sub_lex_capture = (subject, cur_pos, mode_name, sub_text) ->
  sub_start_pos = cur_pos - #sub_text
  m = mode.by_name mode_name
  sub_text, sub_start_pos, ret = sub_lex_capture_start sub_text, sub_start_pos, cur_pos
  append ret, sub_start_pos

  if not m or not m.lexer
    append ret, 'embedded'
    append ret, cur_pos
  else
    append ret, m.lexer(sub_text)
    append ret, "#{mode_name}|embedded"

  unpack ret

pattern_sub_lex_capture = (subject, cur_pos, mode_name, mode_style, sub_text) ->
  real_sub_start_pos = cur_pos - #sub_text
  start_pos = real_sub_start_pos - #mode_name
  m = mode.by_name mode_name
  sub_text, sub_start_pos, ret = sub_lex_capture_start sub_text, real_sub_start_pos, cur_pos

  tinsert ret, 2, real_sub_start_pos
  tinsert ret, 2, mode_style
  tinsert ret, 2, start_pos

  append ret, sub_start_pos

  if not m or not m.lexer
    append ret, 'embedded'
    append ret, cur_pos
  else
    append ret, m.lexer(sub_text)
    append ret, "#{mode_name}|embedded"

  unpack ret

-- START lexer environment --

lexer = {}

-- import lpeg operations and locale patterns
lexer[k] = v for k,v in pairs lpeg when k\match '^%u'
lpeg.locale lexer

setfenv 1, lexer
export *

-- helper patterns
eol = eol_p
blank = blank_p
line_start = -B(1) + B(eol)
float = digit^0 * P'.' * digit^1 * (S'eE' * P('-')^0 * digit^1)^0
hexadecimal = P'0' * S'xX' * xdigit^1 * -#(digit + alpha)
hexadecimal_float =  P'0' * S'xX' * xdigit^1 * (P'.' * xdigit^1)^0 * (S'pP' * S'-+'^0 * xdigit^1)^0 * -#(digit + alpha)

octal = P'0' * R'17'^0 * -#digit

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

word = (...) ->
  word_char = alpha + '_'
  (-B(1) + B(-word_char)) * any(...) * -word_char

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

back_was = (name, value) ->
  Cmt Cb(name) * Cc(value), match_if_equal

complement = (p) ->
  P(1) - p

lenient_pattern = (p) ->
  any {
    p,
    capture('whitespace', S' \t'^0 * eol)
    capture('whitespace', S' \t'^1),
    alpha^1,
    P 1
  }

sub_lex = (mode_name, stop_p) ->
  Cmt(Cc(mode_name) * C(scan_until(stop_p)), sub_lex_capture)

sub_lex_by_pattern = (mode_p, mode_style, stop_p) ->
  Cmt(C(mode_p) * Cc(mode_style) * C(scan_until(stop_p)), pattern_sub_lex_capture)

new = (definition) ->
  setfenv definition, lexer
  pattern = definition!
  setmetatable {
    :pattern
  }, __call: (_, text) ->
    match = lenient_pattern pattern
    p = Ct match^0
    p\match text

setmetatable lexer, __call: (t, ...) -> new ...

return lexer
