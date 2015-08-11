-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.pango'
core = require 'ljglibs.core'

C, ffi_gc, ffi_cast = ffi.C, ffi.gc, ffi.cast

attr_t = ffi.typeof 'PangoAttribute *'
to_attr = (o) -> ffi_cast attr_t, o

core.define 'PangoAttrIterator', {
  next: => C.pango_attr_iterator_next(@) != 0

  range: =>
    vals = ffi.new 'gint[2]'
    C.pango_attr_iterator_range @, vals, vals + 1
    tonumber(vals[0]), tonumber(vals[1])

  get: (type) =>
    v = C.pango_attr_iterator_get @, type
    v != nil and v or nil

}

core.define 'PangoAttrList', {
  properties: {
    iterator: => ffi_gc C.pango_attr_list_get_iterator(@), C.pango_attr_iterator_destroy
  }

  new: ->
    ffi.gc C.pango_attr_list_new!, C.pango_attr_list_unref

  insert: (attr) =>
    C.pango_attr_list_insert @, to_attr ffi_gc(attr, nil)

  insert_before: (attr) =>
    C.pango_attr_list_insert_before @, to_attr ffi_gc(attr, nil)

  change: (attr) =>
    C.pango_attr_list_change @, to_attr ffi_gc(attr, nil)

}, (t, ...) -> t.new ...
