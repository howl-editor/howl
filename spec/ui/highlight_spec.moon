import highlight from howl.ui
import Buffer from howl
flair = require 'aullar.flair'

describe 'highlight', ->

  describe '.define(name, definition)', ->
    it 'defines a highlight and an underlying flair', ->
      highlight.define 'custom', type: highlight.UNDERLINE, foreground: '#334455'
      assert.equal highlight.custom.foreground, '#334455'
      assert.equal flair.get('custom').foreground, '#334455'

  describe 'define_default(name, definition)', ->
    it 'defines the highlight only if it is not already defined', ->
      highlight.define_default 'new_one', type: highlight.UNDERLINE, color: '#334455'
      assert.equal highlight.new_one.color, '#334455'
      highlight.define_default 'new_one', type: highlight.UNDERLINE, color: '#101010'
      assert.equal highlight.new_one.color, '#334455'

  describe '.apply(name, buffer, <table-or-range>)', ->
    it 'sets a highlight marker for the buffer', ->
      buffer = Buffer {}
      buffer.text = 'hƏllo'
      highlight.define 'custom', type: highlight.UNDERLINE, color: '#334455'
      highlight.apply 'custom', buffer, 2, 2
      assert.same {
        { name: 'highlight', flair: 'custom', start_offset: 2, end_offset: 4 }
      }, buffer.markers.all

    it 'accepts a table ranges', ->
      buffer = Buffer {}
      buffer.text = '123456'
      highlight.define 'custom', type: highlight.UNDERLINE, color: '#334455'
      highlight.apply 'custom', buffer, { {2, 2}, {5, 1} }
      assert.same {
        { name: 'highlight', flair: 'custom', start_offset: 2, end_offset: 4 },
        { name: 'highlight', flair: 'custom', start_offset: 5, end_offset: 6 }
      }, buffer.markers.all

  it '.at_pos(buffer, pos) returns a list of the active highlights at pos', ->
    highlight.define 'highlight_bar', type: highlight.UNDERLINE, color: '#334455'
    highlight.define 'highlight_foo', type: highlight.UNDERLINE, color: '#334455'
    buffer = Buffer {}
    buffer.text = 'hƏllo'
    highlight.apply 'highlight_bar', buffer, 1, 4
    assert.same { 'highlight_bar' }, highlight.at_pos(buffer, 1)
    assert.same {}, highlight.at_pos(buffer, 5)

  describe '.remove_all(name, buffer)', ->
    it 'removes all highlights with <name> in <buffer>', ->
      highlight.define 'foo', type: highlight.UNDERLINE, color: '#334455'
      buffer = Buffer {}
      buffer.text = 'ʘne twʘ'
      highlight.apply 'foo', buffer, 1, 3
      highlight.apply 'foo', buffer, 5, 3
      highlight.remove_all 'foo', buffer
      assert.same highlight.at_pos(buffer, 1), { }
      assert.same highlight.at_pos(buffer, 4), { }
      assert.same highlight.at_pos(buffer, 5), { }
      assert.same highlight.at_pos(buffer, 8), { }

  describe '.remove_in_range(name, buffer, start_pos, end_pos)', ->
    it 'removes all highlights with <name> in <buffer> in the range specified (inclusive)', ->
      highlight.define 'foo', type: highlight.UNDERLINE, color: '#334455'
      buffer = Buffer {}
      buffer.text = 'ʘne twʘ'
      highlight.apply 'foo', buffer, 1, 3
      highlight.apply 'foo', buffer, 5, 3
      highlight.remove_in_range 'foo', buffer, 4, 7
      assert.same highlight.at_pos(buffer, 3), { 'foo' }
      assert.same highlight.at_pos(buffer, 5), { }
      assert.same highlight.at_pos(buffer, 8), { }
