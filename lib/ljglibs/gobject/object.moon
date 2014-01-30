ffi = require 'ffi'
require 'ljglibs.cdefs.gobject'
core = require 'ljglibs.core'

C = ffi.C

core.define 'GObject', {
  new: (type) ->
    error 'Undefined gtype passed in', 2 if type == 0 or type == nil
    C.g_object_new type

  ref: (o) ->
    return nil if o == nil
    C.g_object_ref o
    o

  unref: (o) ->
    return nil if o == nil
    C.g_object_unref o
    nil

}, (spec, type) -> spec.new type

