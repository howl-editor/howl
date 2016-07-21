-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Markers = require 'aullar.markers'

describe 'markers', ->
  local markers, listener

  before_each ->
    listener = {
      on_markers_added: spy.new -> nil
      on_markers_removed: spy.new -> nil
    }
    markers = Markers listener

  names = (ms) ->
    n = [m.name for m in *ms]
    table.sort n
    n

  describe 'add(markers)', ->
    it 'raises an error if <data.name> is missing', ->
      assert.raises 'name', -> markers\add { {start_offset: 1, end_offset: 2} }

    it 'raises an error if <data.start_offset> is missing', ->
      assert.raises 'start_offset', -> markers\add { {name: 'test', end_offset: 2} }

    it 'raises an error if <data.end_offset> is missing', ->
      assert.raises 'end_offset', -> markers\add { {name: 'test', start_offset: 2} }

    it 'adds the specified marker for the designated span', ->
      data = name: 'test', my_key: 'my_val', start_offset: 2, end_offset: 4
      markers\add { data }
      assert.same {}, markers\at(1)
      assert.same {data}, markers\at(2)
      assert.same {data}, markers\at(3)
      assert.same {}, markers\at(4)

    it 'notifies the listener', ->
      mks = { {name: 'test', start_offset: 2, end_offset: 4} }
      markers\add mks
      assert.spy(listener.on_markers_added).was_called_with listener, mks

  describe 'for_range(start_offset, end_offset [, selector])', ->
    it 'returns all markers that intersects with the specified span', ->
      markers\add { {name: 'test1', start_offset: 2, end_offset: 5} }
      markers\add { {name: 'test2', start_offset: 4, end_offset: 6} }

      assert.same {'test1'}, names(markers\for_range(1, 4))
      assert.same {'test1', 'test2'}, names(markers\for_range(1, 5))
      assert.same {'test1', 'test2'}, names(markers\for_range(4, 5))
      assert.same {'test2'}, names(markers\for_range(5, 5))
      assert.same {'test2'}, names(markers\for_range(5, 10))
      assert.same {'test1', 'test2'}, names(markers\for_range(1, 30))

    describe 'when <selector> is specified', ->
      it 'only returns markers with fields matching selector', ->
        markers\add { {name: 'test1', start_offset: 2, end_offset: 5, foo: 'bar'} }
        markers\add { {name: 'test2', start_offset: 4, end_offset: 6, frob: 'nic'} }
        assert.same {}, markers\for_range(1, 6, foo: 'other')

  describe 'find(selector)', ->
    it 'finds all markers matching the selector', ->
      markers\add { {name: 'test1', start_offset: 1, end_offset: 2} }
      markers\add { {name: 'test2', start_offset: 1, end_offset: 2} }
      assert.same {
        {name: 'test1', start_offset: 1, end_offset: 2}
      }, markers\find name: 'test1'

      assert.same {
        {name: 'test2', start_offset: 1, end_offset: 2}
      }, markers\find name: 'test2'
      assert.same {}, markers\find foo: 'bar'

  it 'markers can overlap', ->
    markers\add { {name: 'test1', start_offset: 2, end_offset: 4} }
    markers\add { {name: 'test2', start_offset: 3, end_offset: 4} }
    assert.equals 1, #markers\at(2)
    assert.equals 2, #markers\at(3)
    assert.same {'test1', 'test2'}, names(markers\at(3))

  describe 'remove(selector)', ->
    it 'removes all markers matching the selector', ->
      markers\add { {name: 'test1', start_offset: 2, end_offset: 3, foo: 'bar'} }
      markers\add { {name: 'test2', start_offset: 5, end_offset: 6, foo: 'frob'} }
      markers\remove foo: 'frob'
      assert.same {'test1'}, names(markers\for_range(1, 7))
      markers\remove!
      assert.same {}, markers\for_range(1, 7)

    it 'notifies the listener', ->
      markers\add { {name: 'test1', start_offset: 2, end_offset: 3, foo: 'bar'} }
      markers\add { {name: 'test2', start_offset: 5, end_offset: 6, foo: 'frob'} }
      markers\remove foo: 'frob'
      assert.spy(listener.on_markers_removed).was_called_with listener, {
        { name: 'test2', start_offset: 5, end_offset: 6, foo: 'frob' }
      }

  describe 'remove_for_range(start_offset, end_offset [, selector])', ->
    it 'removes all markers within the range', ->
      markers\add { {name: 'test1', start_offset: 2, end_offset: 3} }
      markers\add { {name: 'test2', start_offset: 5, end_offset: 6} }

      markers\remove_for_range 1, 4
      assert.same {}, markers\at(2)

      markers\remove_for_range 4, 10
      assert.same {}, markers\at(5)

    it 'notifies the listener', ->
      markers\add { {name: 'test1', start_offset: 2, end_offset: 3} }
      markers\add { {name: 'test2', start_offset: 5, end_offset: 6} }
      markers\remove_for_range 1, 4
      assert.spy(listener.on_markers_removed).was_called_with listener, {
        { name: 'test1', start_offset: 2, end_offset: 3 }
      }

    describe 'when <selector> is specified', ->
      it 'only removes markers matching the selector', ->
        markers\add { {name: 'test1', start_offset: 2, end_offset: 3, foo: 'bar'} }
        markers\add { {name: 'test2', start_offset: 5, end_offset: 6, foo: 'frob'} }
        markers\remove_for_range 1, 7, foo: 'frob'
        assert.same {'test1'}, names(markers\for_range(1, 7))

  describe 'expand(offset, count)', ->
    it 'bumps all markers below or at <offset> by <count> positions', ->
      markers\add { {name: 'test1', start_offset: 3, end_offset: 4} }
      markers\expand 2, 3
      assert.same {}, markers\at(3)
      assert.same {
        name: 'test1',
        start_offset: 6,
        end_offset: 7
      }, markers\at(6)[1]

      markers\expand 2, 1
      assert.same {}, markers\at(6)
      assert.same {
        name: 'test1',
        start_offset: 7,
        end_offset: 8
      }, markers\at(7)[1]

    it 'expands enclosing markers by <count> positions', ->
      markers\add { {name: 'test1', start_offset: 2, end_offset: 4} }
      markers\expand 3, 2
      assert.same {
        name: 'test1',
        start_offset: 2,
        end_offset: 6
      }, markers\at(2)[1]

      -- but this is outside
      markers\expand 6, 2
      assert.equals 6, markers\at(2)[1].end_offset

      -- and inside by one
      markers\expand 5, 1
      assert.equals 7, markers\at(2)[1].end_offset

  describe 'shrink(offset, count)', ->
    it 'moves all markers above the end offset down by <count> positions', ->
      markers\add { {name: 'test1', start_offset: 5, end_offset: 10} }
      markers\shrink 4, 1
      assert.same {}, markers\at(9)
      assert.same {
        name: 'test1',
        start_offset: 4,
        end_offset: 9
      }, markers\at(4)[1]

      markers\shrink 1, 1
      assert.same {}, markers\at(8)
      assert.same {
        name: 'test1',
        start_offset: 3,
        end_offset: 8
      }, markers\at(3)[1]

    it 'shrinks enclosing markers by <count> positions', ->
      markers\add { {name: 'test1', start_offset: 2, end_offset: 8} }
      markers\shrink 2, 2
      assert.same {
        name: 'test1',
        start_offset: 2,
        end_offset: 6
      }, markers\at(2)[1]

      -- but this is outside
      markers\shrink 6, 2
      assert.equals 6, markers\at(2)[1].end_offset

      -- and inside by one
      markers\shrink 5, 1
      assert.equals 5, markers\at(2)[1].end_offset

    it 'removes partially affected markers', ->
      markers\add { {name: 'test1', start_offset: 2, end_offset: 4} }
      markers\add { {name: 'test2', start_offset: 5, end_offset: 10} }

      markers\shrink 8, 3
      assert.same {}, markers\at(5)

      markers\shrink 1, 3
      assert.same {}, markers\at(2)
