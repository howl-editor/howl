Gtk = require 'ljglibs.gtk'

describe 'Box', ->
  local box

  before_each -> box = Gtk.Box!

  describe '(child properties)', ->
    it 'supports r/w property access through properties_for(child)', ->
      box2 = Gtk.Box!
      box\add box2
      p = box\properties_for box2
      assert.is_false p.expand
      assert.equal Gtk.PACK_START, p.pack_type

      p.expand = true
      p.pack_type = Gtk.PACK_END

      assert.is_true p.expand
      assert.equal Gtk.PACK_END, p.pack_type
