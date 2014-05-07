-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
types = require 'ljglibs.types'

require 'ljglibs.gtk.widget'
require 'ljglibs.glib.list'

C, ffi_cast, ffi_new = ffi.C, ffi.cast, ffi.new
lua_value, cast_widget_ptr = types.lua_value, types.cast_widget_ptr
ref_ptr = gobject.ref_ptr

widget_t = ffi.typeof 'GtkWidget *'
container_t = ffi.typeof 'GtkContainer *'
to_c = (o) -> ffi_cast container_t, o
to_w = (o) -> ffi_cast widget_t, o

jit.off true, true

core.define 'GtkContainer < GtkWidget', {
  properties: {
    focus_child:
      get: => ref_ptr cast_widget_ptr C.gtk_container_get_focus_child to_c(@)
      set: (c) => C.gtk_container_set_focus_child to_c(@), to_w(child)

    children: =>
      list = C.gtk_container_get_children to_c(@)
      children = [ref_ptr(cast_widget_ptr(c)) for i, c in ipairs list]
      list\free
      children

    border_width: 'guint'
    resize_mode: 'GtkResizeMode'
  }

  add: (widget) => C.gtk_container_add to_c(@), to_w(widget)
  remove: (widget) => C.gtk_container_remove to_c(@), to_w(widget)

  properties_for: (child) =>
    props = @.child_properties or {}
    cls =  @.__type
    child = to_w(child)

    setmetatable {}, {
      __index: (t, k) ->
        type = props[k]
        error "No child property '#{k}' found for #{cls}", 2 unless type
        ret = ffi_new "#{type}[1]"
        C.gtk_container_child_get to_c(@), child, k, ret, nil
        lua_value type, ret[0]

      __newindex: (t, k, v) ->
        type = props[k]
        error "No child property '#{k}' found for #{cls}", 2 unless type
        C.gtk_container_child_set to_c(@), child, k, ffi_cast(type, v), nil
    }

}, nil, { no_cast: true }
