gobject = require 'ljglibs.gobject'
require 'ljglibs.cdefs.gtk'
ffi = require 'ffi'
import Type from gobject

describe 'Type', ->
  setup -> ffi.C.gtk_event_box_new!

  describe 'from_name(name)', ->
    it 'returns an id for an existing gtype', ->
      assert.not_equal 0, Type.from_name 'GtkEventBox'

    it 'returns zero for a non-existing gtype', ->
      assert.equal 0, Type.from_name 'WaitWhat?'
