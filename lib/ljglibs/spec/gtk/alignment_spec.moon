Gtk = require 'ljglibs.gtk'

describe 'Alignment', ->
  local alignment

  before_each -> alignment = Gtk.Alignment!

  describe '(properties)', ->
    it 'supports property access', ->
      assert.equal 0.5, alignment.xalign
      alignment.xalign = 0.7
      assert.equal 7, math.ceil alignment.xalign * 10

  describe 'get_padding()', ->
    it 'returns all four paddings as return values (top, bottom, left, right)', ->
      alignment.bottom_padding = 7
      alignment.right_padding = 3
      assert.same {0, 7, 0, 3 }, { alignment\get_padding! }
