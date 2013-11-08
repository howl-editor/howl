-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)
--
-- Destructor object
--
-- Call with the callback and eventual arguments. NB: The callback or arguments
-- can not contain any reference to the holding class, if it does it creates
-- a cyclic dependency that will prevent any garbage collection

ffi = require 'ffi'

ctype = ffi.typeof 'struct {}'

return (callback, ...) ->
  t = ctype!
  args = {...}
  ffi.gc t, -> callback(unpack args) if callback
  return _trigger: t, defuse: -> callback = nil
