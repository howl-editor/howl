gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.window' -- for instantiating the window type
require 'ljglibs.cdefs.gtk'
ffi = require 'ffi'
import Type from gobject

describe 'Type', ->
  describe 'from_name(name)', ->
    it 'returns an id for an existing gtype', ->
      assert.not_equal 0, Type.from_name 'GtkWindow'

    it 'returns nil for a non-existing gtype', ->
      assert.is_nil Type.from_name 'WaitWhat?'

  describe 'name(gtype)', ->
    it 'returns the name for a given gtype', ->
      gtype = Type.from_name 'GtkWindow'
      assert.equals 'GtkWindow', Type.name gtype

  describe 'query(gtype)', ->
    it 'returns a query structure with information about a given type', ->
      gtype = Type.from_name 'GtkWindow'
      info = Type.query gtype
      assert.equal gtype, info.type
      assert.equal 'GtkWindow', ffi.string info.type_name
