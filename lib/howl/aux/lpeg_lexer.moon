import P, B, S, Cp, Cc, Ct from lpeg
import pairs, setfenv, setmetatable from _G
l = lpeg.locale!
import space, alpha from l

lexer = {}

-- import lpeg operations and locale patterns
lexer[k] = v for k,v in pairs lpeg when k\match '^%u'
lpeg.locale lexer

setfenv 1, lexer
export *

capture = (style, pattern) ->
  Cp! * pattern * Cc(style) * Cp!

any = (args) ->
  arg_p = P args[1]
  arg_p += args[i] for i = 2, #args
  arg_p

word = (args) ->
  word_char = alpha + '_'
  (-B(1) + B(-word_char)) * any(args) * -word_char

scan_to = (stop_p, escape_p) ->
  stop_p = P(stop_p)
  skip = (-stop_p * 1)
  skip = (P(escape_p) * 1) + skip if escape_p
  skip^0 * (stop_p + P-1)

span = (start_p, stop_p, escape_p) ->
  start_p * scan_to stop_p, escape_p

eol = S('\n\r')^1

new = (definition) ->
  setfenv definition, lexer
  pattern = definition!
  setmetatable {}, __call: (_, text) ->
    match = any {
      pattern,
      capture('whitespace', space^1),
    }
    p = Ct match^0
    p\match text

setmetatable lexer, __call: (t, ...) -> new ...

return lexer