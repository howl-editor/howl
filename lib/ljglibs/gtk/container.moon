-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
types = require 'ljglibs.types'
require 'ljglibs.gtk.widget'

C, ffi_cast, ffi_new = ffi.C, ffi.cast, ffi.new
lua_value = types.lua_value

widget_t = ffi.typeof 'GtkWidget *'
container_t = ffi.typeof 'GtkContainer *'
_ = (o) -> ffi_cast container_t, o

core.define 'GtkContainer < GtkWidget', {
  add: (widget) => C.gtk_container_add _(@), ffi_cast(widget_t, widget)
  remove: (widget) => C.gtk_container_remove _(@), ffi_cast(widget_t, widget)

  properties_for: (child) =>
    props = @.child_properties
    child = ffi_cast(widget_t, child)

    setmetatable {}, {
      __index: (t, k) ->
        type = props[k]
        error "No child property '#{k}' found" unless type
        ret = ffi_new "#{type}[1]"
        C.gtk_container_child_get _(@), child, k, ret
        lua_value type, ret[0]

      __newindex: (t, k, v) ->
        type = props[k]
        error "No child property '#{k}' found" unless type
        C.gtk_container_child_set _(@), child, k, ffi_cast(type, v)
    }

}, nil, { no_cast: true }
