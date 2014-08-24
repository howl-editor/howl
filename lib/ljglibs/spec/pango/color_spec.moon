Color = require 'ljglibs.pango.color'

describe 'Color', ->
  describe '(construction)', ->
    it 'accepts the color values as (r, g, b)', ->
      color = Color 1, 2, 3
      assert.equal 1, color.red
      assert.equal 2, color.green
      assert.equal 3, color.blue

    it 'accepts a single string containing a specification', ->
      color = Color '#ff00ff'
      assert.equal 65535, color.red
      assert.equal 0, color.green
      assert.equal 65535, color.blue

  it 'tostring(color) returns the color specification', ->
      color = Color '#ff00ff'
      assert.equal '#ffff0000ffff', tostring color
