-- Destructor object
-- Call with the callback

ffi = require 'ffi'

ctype = ffi.typeof 'struct {}'

return (callback, ...) ->
  t = ctype!
  args = {...}
  ffi.gc t, -> callback unpack args
  t
