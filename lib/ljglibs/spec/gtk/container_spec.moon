Gtk = require 'ljglibs.gtk'

describe 'Container', ->
  local container

  before_each -> container = Gtk.Box!

  describe '.children', ->
    it 'is a table of all children', ->
      child1 = Gtk.Box!
      child2 = Gtk.Box!
      container\add child1
      container\add child2
      assert.same { child1, child2 }, container.children

    it 'retains type information when possible', ->
      child1 = Gtk.Box!
      container\add child1
      assert.equal 'GtkBox', container.children[1].__type
