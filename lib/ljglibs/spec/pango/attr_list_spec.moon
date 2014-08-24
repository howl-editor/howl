Pango = require 'ljglibs.pango'
import Attribute, AttrList from Pango

describe 'AttrList', ->
  local list

  before_each -> list = AttrList!

  describe '.iterator', ->
    it 'next() returns true until all attributes are exhausted', ->
      iterator = list.iterator
      assert.is_false iterator\next!

      list\insert Attribute.Underline(true)
      iterator = list.iterator
      assert.is_true iterator\next!
      assert.is_false iterator\next!

    it 'range() returns the start and end indices of the current segment', ->
      list\insert Attribute.Underline(true, 2, 5)
      iterator = list.iterator
      iterator\next!
      assert.same { 2, 5 }, { iterator\range! }

    it 'get(type) returns the attribute of the given type, if any', ->
      sthrough = Attribute.Strikethrough(true, 0, 3)
      list\insert sthrough
      uline = Attribute.Underline(true, 2, 5)
      list\insert uline
      iterator = list.iterator
      assert.equal sthrough, iterator\get Attribute.STRIKETHROUGH
      iterator\next!
      assert.equal uline, iterator\get Attribute.UNDERLINE
      assert.is_nil iterator\get Attribute.BACKGROUND
