Pango = require 'ljglibs.pango'
TabArray = Pango.TabArray

describe 'TabArray', ->
  describe '.size', ->
    it 'is the number of tab stops', ->
      assert.equals 2, TabArray(2, false).size

  describe 'getting and setting tabs', ->
    it 'works using get_tab and set_tab', ->
      ta = TabArray(2, false)
      ta\set_tab 0, Pango.TAB_LEFT, 8
      ta\set_tab 1, Pango.TAB_LEFT, 4
      assert.same { alignment: Pango.TAB_LEFT, location: 8 }, ta\get_tab(0)
      assert.same { alignment: Pango.TAB_LEFT, location: 4 }, ta\get_tab(1)

    it 'raises an error when trying to get or set an out-of-bounds tab', ->
      ta = TabArray(2, false)
      assert.raises 'Invalid tab stop', -> ta\set_tab 2, Pango.TAB_LEFT, 8
      assert.raises 'Invalid tab stop', -> ta\get_tab 2

  describe '.tabs', ->
    it 'provides an luaish way of treating the tab stops as a table', ->
      ta = TabArray(2, false)
      ta.tabs[1] = 4
      ta.tabs[2] = 2
      assert.equal 4, ta.tabs[1]
      assert.equal 2, ta.tabs[2]

    it 'returns nil for out-of-bounds gets', ->
      ta = TabArray(2, false)
      assert.is_nil ta.tabs[3]

  describe 'construction', ->
    it 'passing a number as the third parameter sets all tab stops to multiple', ->
      ta = TabArray(3, false, 4)
      assert.equal 4, ta.tabs[1]
      assert.equal 8, ta.tabs[2]
      assert.equal 12, ta.tabs[3]
