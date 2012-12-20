local lpeg = require 'lpeg'
local P, S, V  = lpeg.P, lpeg.S, lpeg.V

mod = {
  eof = P(-1)
}
lpeg.locale(mod)

return mod