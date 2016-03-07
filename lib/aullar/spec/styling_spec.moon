-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Styling = require 'aullar.styling'
ffi = require 'ffi'

describe 'Styling', ->

  local styling, listener

  before_each ->
    listener = on_changed: spy.new -> nil
    styling = Styling 50, listener

  describe 'Styling.sub(styling, start_offset, end_offset)', ->
    it 'extracts a sub set of styling for [start_offset, end_offset) from styling', ->
      styles = {
        3, 'keyword', 5,
        6, 'string', 8,
      }

      assert.same styles, Styling.sub(styles, 1, 10)
      assert.same {}, Styling.sub(styles, 1, 3)
      assert.same {}, Styling.sub(styles, 8, 10)

      -- precise hit
      assert.same { 1, 'keyword', 3 }, Styling.sub(styles, 3, 5)

      -- overlap from start
      assert.same { 1, 'keyword', 2 }, Styling.sub(styles, 3, 4)

      -- overlap from end
      assert.same { 1, 'string', 2 }, Styling.sub(styles, 7, 10)

      -- overlap in the middle
      assert.same {
        1, 'keyword', 2,
        3, 'string', 4
      }, Styling.sub(styles, 4, 7)


  describe 'set(start_offset, end_offset, style)', ->
    it 'sets the specified style for the range [start_offset, end_offset)', ->
      styling\set 3, 8, 'keyword'
      assert.same { 3, 'keyword', 9 }, styling\get(1, 8)

    it 'handles setting styling over the buffer gap', ->
      styling.style_buffer\move_gap_to 5
      styling\set 3, 8, 'keyword'
      assert.same { 3, 'keyword', 9 }, styling\get(1, 8)
      styling\set 3, 6, 'operator'
      assert.same { 3, 'operator', 7, 7, 'keyword', 9 }, styling\get(1, 8)

      styling\set 6, 8, 'keyword'
      assert.same { 3, 'operator', 6, 6, 'keyword', 9 }, styling\get(1, 8)

    it 'end_offset is inclusive', ->
      styling\set 1, 2, 'keyword'
      styling\set 1, 1, 'operator'
      assert.same { 1, 'operator', 2, 2, 'keyword', 3 }, styling\get(1, 2)

    it 'updates .last_pos_styled to the last line styled', ->
      assert.equals 0, styling.last_pos_styled

      styling\set 1, 1, 'keyword'
      assert.equals 1, styling.last_pos_styled

      styling\set 8, 9, 'keyword'
      assert.equals 9, styling.last_pos_styled

      styling\set 6, 7, 'keyword'
      assert.equals 9, styling.last_pos_styled

    it 'notifies the listener', ->
      styling\set 8, 9, 'keyword'
      assert.spy(listener.on_changed).was_called_with listener, 8, 9

  describe 'get(start_offset, end_offset)', ->
    it 'returns a table of styles and positions for the given range, same as styles argument to apply', ->
      styling\set 3, 8, 'keyword'
      assert.same { 3, 'keyword', 9 }, styling\get(1, 8)

    it 'returns the style positions relative to the offset', ->
      styling\set 3, 8, 'keyword'
      assert.same { 1, 'keyword', 7 }, styling\get(3, 8)

    it 'end_offset is inclusive', ->
      styles = { 1, 's1', 2, 2, 's2', 4 }
      styling\apply 1, styles
      assert.same { 1, 's1', 2 }, styling\get(1, 1)

  describe 'invalidate_from(offset)', ->
    it 'removes styling from <offset> and forward', ->
      styling\set 2, 9, 'keyword'
      styling\invalidate_from 7
      assert.same { 2, 'keyword', 7 }, styling\get(1, 9)
      assert.same {}, styling\get(7, 9)

      styling\invalidate_from 2
      assert.same {}, styling\get(1, 9)

    it 'handles invalidations over the buffer gap', ->
      styling\set 1, 6, 'keyword'
      styling.style_buffer\move_gap_to 4 -- 5, 1-offset
      styling\invalidate_from 3
      assert.same { 1, 'keyword', 3 }, styling\get(1, 6)

    it 'updates .last_pos_styled', ->
      styling\set 2, 9, 'keyword'
      styling\invalidate_from 3
      assert.equals 2, styling.last_pos_styled
      styling\invalidate_from 6
      assert.equals 2, styling.last_pos_styled
      styling\invalidate_from 1
      assert.equals 0, styling.last_pos_styled

    it 'notifies the listener about the invalidated range', ->
      styling\set 1, 10, 'keyword'
      styling\invalidate_from 4
      assert.spy(listener.on_changed).was_called_with listener, 4, 10

  describe 'insert(offset, count)', ->
    it 'inserts <count> positions, shifting existing styling up', ->
      styling\set 1, 5, 'keyword'
      styling\insert 3, 2
      assert.same { 1, 'keyword', 3, 5, 'keyword', 8 }, styling\get(1, 7)

    it 'updated last_pos_styled', ->
      styling\set 1, 5, 'keyword'
      styling\insert 3, 2
      assert.equals 7, styling.last_pos_styled

    it 'notifies the listener about the new unstyled span', ->
      styling\set 1, 10, 'keyword'
      styling\insert 3, 2
      assert.spy(listener.on_changed).was_called_with listener, 3, 4

  describe 'delete(offset, count)', ->
    it 'deletes <count> positions, shifting existing styling down', ->
      styling\set 1, 3, 'keyword'
      styling\set 4, 5, 'string'
      styling\delete 3, 2
      assert.same { 1, 'keyword', 3, 3, 'string', 4 }, styling\get(1, 3)

    it 'updated last_pos_styled', ->
      styling\set 1, 5, 'keyword'
      styling\delete 4, 3
      assert.equals 4, styling.last_pos_styled
      styling\delete 2, 1
      assert.equals 3, styling.last_pos_styled

    it 'notifies the listener about the deleted span', ->
      styling\set 1, 10, 'keyword'
      styling\delete 3, 2
      assert.spy(listener.on_changed).was_called_with listener, 3, 4

  describe 'clear(start_offset, end_offset)', ->
    it 'clears the styling for positions [start_offset - end_offset]', ->
      styling\set 1, 5, 'keyword'
      styling\clear 2, 2
      assert.same { 1, 'keyword', 2, 3, 'keyword', 6 }, styling\get(1, 5)
      styling\clear 3, 5
      assert.same { 1, 'keyword', 2 }, styling\get(1, 5)

    it 'notifies the listener about the cleared span', ->
      styling\set 1, 10, 'keyword'
      styling\clear 3, 5
      assert.spy(listener.on_changed).was_called_with listener, 3, 5

  describe 'at(offset)', ->
    it 'returns the style at the specified position', ->
      styling\set 1, 2, 'keyword'
      styling\set 2, 5, 'string'
      styling\set 5, 6, 'operator'

      assert.equals 'keyword', styling\at 1
      assert.equals 'string', styling\at 2
      assert.equals 'string', styling\at 4
      assert.equals 'operator', styling\at 5
      styling\set styling.style_buffer.size, styling.style_buffer.size, 'operator'
      assert.equals 'operator', styling\at(styling.style_buffer.size)

    it 'accounts for the gap', ->
      styling\set 1, 6, 'keyword'
      styling.style_buffer\move_gap_to 2
      styling\set 1, 6, 'string'
      assert.equals 'string', styling\at 3

    it 'returns nil for out of boundary positions', ->
      styling\set 1, 4, 'keyword'
      assert.is_nil styling\at 0
      assert.is_nil styling\at 5
      assert.is_nil styling\at styling.style_buffer.size + 1

    it 'returns nil for unstyled positions', ->
      assert.is_nil styling\at 1

  describe 'apply(offset, styling)', ->
    it 'sets the styling for the relevant buffer portion', ->
      styling\apply 1, { 3, 'keyword', 8 }
      assert.same { 3, 'keyword', 8 }, styling\get(1, 20)

    it 'handles <offset> not being at the start of the buffer', ->
      styling\apply 5, { 1, 'keyword', 5 }
      styling\apply 10, { 8, 'string', 10 }
      assert.same { 5, 'keyword', 9 }, styling\get(1, 11)
      assert.same { 8, 'string', 10 }, styling\get(10, 29)

    it 'handles merging of already existing styles', ->
      styling\apply 1, { 1, 'operator', 2 }
      styling\apply 1, { 9, 'string', 13 }
      assert.same { 1, 'operator', 2, 9, 'string', 13 }, styling\get(1, 13)
      styling\apply 1, { 3, 'string', 8 }
      assert.same { 1, 'operator', 2, 3, 'string', 8, 9, 'string', 13 }, styling\get(1, 13)

    it 'updates .last_pos_styled', ->
      assert.equals 0, styling.last_pos_styled

      styling\apply 1, { 1, 'operator', 2 }
      assert.equals 1, styling.last_pos_styled

      styling\apply 1, { 5, 'operator', 6 }
      assert.equals 5, styling.last_pos_styled

      styling\apply 1, { 8, 'operator', 10 }
      assert.equals 9, styling.last_pos_styled

      styling\apply 1, { 1, 'operator', 2 }
      assert.equals 9, styling.last_pos_styled

    it 'handles applying styling over the buffer gap', ->
      styling.style_buffer\move_gap_to 5
      styling\apply 1, { 3, 'keyword',  8 }
      assert.same { 3, 'keyword', 8 }, styling\get(1, 10)

    it 'notifies the listener about the actually styled span', ->
      styling\apply 1, { 2, 'operator', 3, 4, 'string', 5 }
      assert.spy(listener.on_changed).was_called_with listener, 2, 4

    context 'sub lexing', ->
      it 'automatically styles using extended styles when requested', ->
        styling\apply 1, {
          1, 'operator', 2,
          2, { 1, 's2', 2, 2, 's3', 3 }, 'my_sub|s1',
          4, 's2', 5
          6, { 1, 's2', 2 }, 'my_sub|s1',
        }
        assert.same {
          1, 'operator', 2,
          2, 's1:s2', 3,
          3, 's1:s3', 4,
          4, 's2', 5
          6, 's1:s2', 7
        }, styling\get(1, 7)

        assert.same nil, styling\get_nearest_style_marker 1
        marker =
          name: 'my_sub'
          start_offset: 2
          end_offset: 5
        assert.same marker, styling\get_nearest_style_marker 2
        assert.same marker, styling\get_nearest_style_marker 3
        assert.same marker, styling\get_nearest_style_marker 4
        assert.same nil, styling\get_nearest_style_marker 5

        marker =
          name: 'my_sub'
          start_offset: 6
          end_offset: 8
        assert.same marker, styling\get_nearest_style_marker 6
        assert.same marker, styling\get_nearest_style_marker 7
        assert.same nil, styling\get_nearest_style_marker 8

      it 'styles any holes with the base style', ->
        styling\apply 1, {
          1, { 2, 's3', 3, 7, 's4', 8 }, 'my_sub|s1'
        }
        assert.same {
          1, 's1', 2,
          2, 's1:s3', 3
          3, 's1', 7,
          7, 's1:s4', 8,
        }, styling\get(1, 8)

      it 'accounts for the offset parameter', ->
        styling\apply 3, {
          1, { 2, 's3', 3 }, 'my_sub|s1'
        }
        assert.same {
          1, 's1', 2,
          2, 's1:s3', 3
        }, styling\get(3, 6)

      it 'accounts for the offset of the embedded style', ->
        styling\apply 1, {
          3, { 2, 's3', 3 }, 'my_sub|s1'
        }
        assert.same {
          3, 's1', 4,
          4, 's1:s3', 5
        }, styling\get(1, 5)

      it 'notifies the listener about the actually styled span', ->
        styling\apply 1, {
          3, { 2, 's3', 3 }, 'my_sub|s1'
        }
        assert.spy(listener.on_changed).was_called_with listener, 3, 5

      it 'handles empty sub lexing elements', ->
        styling\apply 1, {
          1, 's1', 2,
          2, {}, 'my_sub|s1'
        }
        assert.same {
          1, 's1', 2,
        }, styling\get(1, 4)


      it 'handles nested sub lexing', ->
        -- ">'x'"
        styling\apply 1, {
          1, {
            1, 'operator', 2,
            2, {
              1, 'string', 4
            }, 'my_sub|s2'
          }, 'my_sub|s1'
        }

        assert.same {
          1, 's1:operator', 2,
          2, 's2:string', 5,
        }, styling\get(1, 5)

      it 'handles empty nested sub style elements', ->
        styling\apply 1, {
          1, 's1', 2, 2, {
            1, 's3', 2,
            2, {}, 'sub2|s2',
            3, {
              1, {}, 'subsub1|s2'
            }, 'sub3|s2'
          }, 'my_sub|s1'
        }
        assert.same {
          1, 's1', 2,
          2, 's1:s3', 3,
        }, styling\get(1, 6)

  describe 'get_nearest_style_marker(pos)', ->
    it 'generally works', ->
      styling\apply 1, {
        1, 'operator', 2,
        2, { 1, 's2', 2, 2, 's3', 3 }, 'my_sub|s1'
      }

      assert.same nil, styling\get_nearest_style_marker 1
      marker =
        name: 'my_sub'
        start_offset: 2
        end_offset: 5
      assert.same marker, styling\get_nearest_style_marker 2
      assert.same marker, styling\get_nearest_style_marker 3
      assert.same marker, styling\get_nearest_style_marker 4
      assert.same nil, styling\get_nearest_style_marker 5

    it 'works with nested sub modes', ->
      styling\apply 1, {
        1, {
          1, 'operator', 2,
          2, {
            1, 'string', 4
          }, 'my_sub2|s2'
        }, 'my_sub1|s1'
      }

      marker1 =
        name: 'my_sub1'
        start_offset: 1
        end_offset: 6

      marker2 =
        name: 'my_sub2'
        start_offset: 2
        end_offset: 6

      assert.same marker1, styling\get_nearest_style_marker 1
      assert.same marker2, styling\get_nearest_style_marker 2
      assert.same marker2, styling\get_nearest_style_marker 3
      assert.same marker2, styling\get_nearest_style_marker 4
      assert.same marker2, styling\get_nearest_style_marker 5

  describe '(run-through)', ->
    it 'generally works', ->
      styling\set 1, 10, 'keyword'
      assert.same { 1, 'keyword', 11 }, styling\get(1, 10)
      styling\insert 2, 1
      assert.same { 1, 'keyword', 2, 3, 'keyword', 12 }, styling\get(1, 11)
      styling\apply 1, { 1, 'string', 4, 4, 'operator', 12 }
      assert.same { 1, 'string', 4, 4, 'operator', 12 }, styling\get(1, 11)
      styling\delete 1, 2
      assert.same { 1, 'string', 2, 2, 'operator', 10 }, styling\get(1, 10)
