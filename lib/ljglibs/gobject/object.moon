ffi = require 'ffi'
require 'ljglibs.cdefs.gobject'
core = require 'ljglibs.core'

C = ffi.C

core.define 'GObject', {
  new: (type) ->
    error 'Undefined type passed in (zero)', 2 if type == 0
    C.g_object_new type

}, (spec, type) -> spec.new type

