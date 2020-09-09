import Buffer from howl

describe 'BufferMarkers', ->
  local buffer, markers

  names = (ms) ->
    n = [m.name for m in *ms]
    table.sort n
    n

  before_each ->
    buffer = Buffer {}
    markers = buffer.markers

  describe 'add(markers)', ->
    it 'raises an error if <.name> is missing', ->
      assert.raises 'name', -> markers\add { {start_offset: 1, end_offset: 2} }

    it 'raises an error if <.start_offset> is missing', ->
      buffer.text = '12'
      assert.raises 'start_offset', -> markers\add { {name: 'test', end_offset: 2} }

    it 'raises an error if <.end_offset> is missing', ->
      buffer.text = '12'
      assert.raises 'end_offset', -> markers\add { {name: 'test', start_offset: 2} }

    it 'raises an error if <.start_offset> is out of bounds', ->
      buffer.text = '12'
      assert.raises 'offset', ->
        markers\add { {name: 'test', start_offset: 4, end_offset: 4} }

      assert.raises 'offset', ->
        markers\add { {name: 'test', start_offset: 0, end_offset: 2} }

    it 'raises an error if <.end_offset> is out of bounds', ->
      buffer.text = '12'
      assert.raises 'offset', ->
        markers\add { {name: 'test', start_offset: 1, end_offset: 4} }

      assert.raises 'offset', ->
        markers\add { {name: 'test', start_offset: 1, end_offset: 0} }

    it 'adds the specified marker for the designated span', ->
      buffer.text = 'åäöx'
      mks = { {name: 'test', start_offset: 2, end_offset: 4} }
      markers\add mks
      assert.same {}, markers\at(1)
      assert.same mks, markers\at(2)
      assert.same mks, markers\at(3)
      assert.same {}, markers\at(4)

    it 'allows specifying bytes offsets using byte_{start,end}_offset', ->
      buffer.text = 'åäöx'
      mks = { {name: 'test', byte_start_offset: 3, byte_end_offset: 5} }
      adjusted = { {name: 'test', start_offset: 2, end_offset: 3} }
      markers\add mks
      assert.same {}, markers\at(1)
      assert.same adjusted, markers\at(2)
      assert.same {}, markers\at(3)

  describe 'for_range(start_offset, end_offset)', ->
    it 'returns all markers that intersects with the specified span', ->
      buffer.text = 'åäö€ᛖ'
      markers\add { {name: 'test1', start_offset: 2, end_offset: 5} }
      markers\add { {name: 'test2', start_offset: 4, end_offset: 6} }

      assert.same {'test1'}, names(markers\for_range(1, 4))
      assert.same {'test1', 'test2'}, names(markers\for_range(1, 5))
      assert.same {'test1', 'test2'}, names(markers\for_range(4, 5))
      assert.same {'test2'}, names(markers\for_range(5, 5))
      assert.same {'test2'}, names(markers\for_range(5, 10))
      assert.same {'test1', 'test2'}, names(markers\for_range(1, 6))

  describe 'find(selector)', ->
    it 'finds all markers matching the selector', ->
      buffer.text = 'åäö€ᛖ'
      markers\add { {name: 'test1', start_offset: 1, end_offset: 2} }
      markers\add { {name: 'test2', start_offset: 3, end_offset: 5} }
      assert.same {
        {name: 'test1', start_offset: 1, end_offset: 2}
      }, markers\find name: 'test1'

      assert.same {
        {name: 'test2', start_offset: 3, end_offset: 5}
      }, markers\find name: 'test2'
      assert.same {}, markers\find foo: 'bar'

  describe 'remove(selector)', ->
    it 'removes all markers matching the selector', ->
      buffer.text = 'åäö€ᛖ'
      markers\add { {name: 'test1', start_offset: 2, end_offset: 3, foo: 'bar'} }
      markers\add { {name: 'test2', start_offset: 5, end_offset: 6, foo: 'frob'} }
      markers\remove foo: 'frob'
      assert.same {'test1'}, names(markers\for_range(1, 7))
      markers\remove!
      assert.same {}, markers\for_range(1, 7)

    it 'can be used to remove markers returned by find', ->
      buffer.text = 'åäö€ᛖ'
      markers\add { {name: 'test1', start_offset: 3, end_offset: 4, foo: 'bar'} }
      for marker in *markers\find name: 'test1'
        markers\remove marker
      assert.same {}, markers\find!

    it 'can remove markers via start and end offset values', ->
      buffer.text = 'åäö€ᛖ'
      markers\add { {name: 'test1', start_offset: 1, end_offset: 3, foo: 'bar'} }
      markers\add { {name: 'test2', start_offset: 4, end_offset: 5, foo: 'bar'} }
      markers\remove start_offset: 1
      markers\remove end_offset: 5
      assert.same {}, markers\find!

  describe 'remove_for_range(start_offset, end_offset, selector)', ->
    it 'removes all markers within the range', ->
      buffer.text = 'åäö€ᛖ'
      markers\add { {name: 'test1', start_offset: 2, end_offset: 3} }
      markers\add { {name: 'test2', start_offset: 5, end_offset: 6} }

      markers\remove_for_range 1, 4
      assert.same {}, markers\at(2)

      markers\remove_for_range 4, 10
      assert.same {}, markers\at(5)

    describe 'when <selector> is specified', ->
      it 'only removes markers matching the selector', ->
        buffer.text = 'åäö€ᛖ'
        markers\add { {name: 'test1', start_offset: 2, end_offset: 3, foo: 'bar'} }
        markers\add { {name: 'test2', start_offset: 5, end_offset: 6, foo: 'frob'} }

        markers\remove_for_range 1, 6, foo: 'frob'
        assert.same {'test1'}, names(markers\for_range(1, 7))

  describe 'upon buffer modifications', ->
    it 'markers move with inserts', ->
      buffer.text = 'åäö€ᛖ'
      markers\add { {name: 'test1', start_offset: 2, end_offset: 3} }
      buffer\insert '∀', 1
      assert.same {
        { name: 'test1', start_offset: 3, end_offset: 4 }
      }, markers.all

    it 'markers expand with inserts', ->
      buffer.text = 'åäö€ᛖ'
      markers\add { {name: 'test1', start_offset: 2, end_offset: 4} }
      buffer\insert '∀', 3
      assert.same {
        { name: 'test1', start_offset: 2, end_offset: 5 }
      }, markers.all

    it 'markers move with deletes', ->
      buffer.text = 'åäö€ᛖ'
      markers\add { {name: 'test1', start_offset: 3, end_offset: 5} }
      buffer\delete 2, 2
      assert.same {
        { name: 'test1', start_offset: 2, end_offset: 4 }
      }, markers.all

    it 'markers shrink with deletes', ->
      buffer.text = 'åäö€ᛖ'
      markers\add { {name: 'test1', start_offset: 2, end_offset: 5} }
      buffer\delete 3, 3
      assert.same {
        { name: 'test1', start_offset: 2, end_offset: 4 }
      }, markers.all
