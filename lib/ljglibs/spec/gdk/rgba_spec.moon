RGBA = require 'ljglibs.gdk.rgba'

describe 'RGBA', ->
  describe '(construction)', ->
    it 'accepts an optional spec', ->
      rgb = RGBA '#00ff7f'
      assert.equal 0, rgb.red
      assert.equal 1, rgb.green
      assert.equal 5, math.ceil(rgb.blue * 10)

  describe 'parse(spec)', ->
    it 'creates a RGBA instance from the spec', ->
      rgb = RGBA!
      rgb\parse '#00ff7f'
      assert.equal 0, rgb.red
      assert.equal 1, rgb.green
      assert.equal 5, math.ceil(rgb.blue * 10)
