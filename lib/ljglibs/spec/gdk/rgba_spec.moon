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

  it 'tostring(rgba) returns a textual representation', ->
    rgb = RGBA '#00ff80'
    assert.equal 'rgb(0,255,128)', tostring(rgb)
    rgb.alpha = 0.5
    assert.equal 'rgba(0,255,128,0.5)', tostring(rgb)
