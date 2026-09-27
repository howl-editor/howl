Snapshot = require 'ljglibs.gtk.snapshot'
Renderer = require 'ljglibs.gsk.renderer'
Display = require 'ljglibs.gdk.display'
RGBA = require 'ljglibs.gdk.rgba'
Pixbuf = require 'ljglibs.gdk.pixbuf'

describe 'Snapshot', ->
  local renderer

  before_each -> renderer = Renderer.new_cairo Display.get_default!
  after_each -> renderer\unrealize!

  it 'renders what was appended to a texture of the viewport size', ->
    snapshot = Snapshot!
    snapshot\append_color RGBA('#ff0000'), 0, 0, 20, 10
    texture = renderer\render_texture snapshot\to_node!, 0, 0, 20, 10
    assert.equal 20, texture.width
    assert.equal 10, texture.height

  it 'scales what is appended after scale()', ->
    snapshot = Snapshot!
    snapshot\scale 2, 2
    snapshot\append_color RGBA('#ff0000'), 0, 0, 20, 10
    texture = renderer\render_texture snapshot\to_node!, 0, 0, 40, 20
    assert.equal 40, texture.width

  it 'returns nil from to_node() when nothing was appended', ->
    assert.is_nil Snapshot!\to_node!

  describe 'a rendered texture', ->
    it 'saves to a PNG with save_to_png(filename)', ->
      snapshot = Snapshot!
      snapshot\translate 5, 0
      snapshot\append_color RGBA('#00ff00'), 0, 0, 5, 4
      texture = renderer\render_texture snapshot\to_node!, 0, 0, 10, 4
      with_tmpdir (dir) ->
        file = dir / 'shot.png'
        texture\save_to_png file.path
        pb = Pixbuf.new_from_file file.path
        assert.equal 10, pb.width
        assert.equal 4, pb.height
