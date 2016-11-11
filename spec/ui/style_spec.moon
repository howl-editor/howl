import style, ActionBuffer from howl.ui
import Buffer from howl

describe 'style', ->
  local buffer

  before_each ->
      buffer = Buffer {}

  it 'styles can be accessed using direct indexing', ->
    t = styles: default: color: '#998877'
    style.set_for_theme t
    assert.equal style.default.color, t.styles.default.color

  describe '.define(name, definition)', ->
    it 'allows defining custom styles', ->
      style.define 'custom', color: '#334455'
      assert.equal style.custom.color, '#334455'

    it 'allows aliasing styles using a string as <definition>', ->
      style.define 'target', color: '#beefed'
      style.define 'alias', 'target'
      assert.equal '#beefed', style.alias.color

  describe 'define_default(name, definition)', ->
    it 'defines the style only if it is not already defined', ->
      style.define_default 'preset', color: '#334455'
      assert.equal style.preset.color, '#334455'

      style.define_default 'preset', color: '#667788'
      assert.equal style.preset.color, '#334455'

  it '.at_pos(buffer, pos) returns name and style definition at pos', ->
    style.define 'stylish', color: '#101010'
    buffer = ActionBuffer!
    buffer\insert 'hƏllo', 1, 'keyword'
    buffer\insert 'Bačon', 6, 'stylish'

    name = style.at_pos(buffer, 5)
    assert.equal name, 'keyword'
