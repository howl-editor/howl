gobject = require 'ljglibs.gobject'
import Object, Type from gobject

describe 'Object', ->
  context '(constructing)', ->
    it 'can be created using an existing gtype', ->
      type = Type.from_name 'GtkButton'
      o = Object type
      assert.is_not_nil o

    it 'raises an error if type is zero', ->
      type = Type.from_name 'GtkButton2'
      assert.raises 'undefined', -> Object type
