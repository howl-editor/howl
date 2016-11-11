-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
--
-- Destructor object
--
-- Call with the callback and eventual arguments. NB: The callback or arguments
-- can not contain any reference to the holding class, if it does it creates
-- a cyclic dependency that will prevent any garbage collection

ffi = require 'ffi'
unpack = table.unpack

ctype = ffi.typeof 'struct {}'

return (callback, ...) ->
  t = ctype!
  args = {...}
  ffi.gc t, -> callback(unpack args) if callback
  return _trigger: t, defuse: -> callback = nil
