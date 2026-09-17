gobject = require 'ljglibs.gobject'
Gtk = require 'ljglibs.gtk'
import Object, Type from gobject

describe 'Object', ->
  setup ->
    -- force init
    Gtk.Box Gtk.ORIENTATION_VERTICAL, 7

  context '(constructing)', ->
    it 'can be created using an existing gtype', ->
      type = Type.from_name 'GtkBox'
      o = Object type
      assert.is_not_nil o

    it 'raises an error if type is nil', ->
      type = Type.from_name 'GtkButton2'
      assert.raises 'undefined', -> Object type

  describe 'get_typed(k, type)', ->
    it 'returns a property value converted according to <type>', ->
      box = Gtk.Box Gtk.ORIENTATION_VERTICAL, 7
      spacing = box\get_typed 'spacing', 'gint'
      assert.equal 7, spacing
      assert.equal 'number', type spacing

      homogeneous = box\get_typed 'homogeneous', 'gboolean'
      assert.is_false homogeneous

      name = box\get_typed 'name', 'gchar*'
      assert.equal 'string', type name

  describe 'set_typed(k, type, v)', ->
    it 'converts value according to <type> before setting it', ->
      box = Gtk.Box Gtk.ORIENTATION_VERTICAL, 7
      box\set_typed 'spacing', 'gint', 3.1
      assert.equal 3, box\get_typed 'spacing', 'gint'

      box\set_typed 'homogeneous', 'gboolean', true
      assert.is_true box\get_typed 'homogeneous', 'gboolean'

      box\set_typed 'name', 'gchar*', 'myname'
      assert.equal 'myname', box\get_typed 'name', 'gchar*'
