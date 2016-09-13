-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import inspect, inspection, Buffer, mode from howl

describe 'inspect', ->
  local buffer, inspector

  before_each ->
    mode.register name: 'inspect-mode', create: -> {}
    inspector = spy.new -> {}
    inspection.register name: 'test-inspector', factory: -> inspector
    buffer = Buffer mode.by_name('inspect-mode')

  after_each ->
    mode.unregister 'inspect-mode'
    inspection.unregister 'test-inspector'

  describe 'inspect(buffer)', ->
    it 'runs inspectors specified for the buffer', ->
      buffer.config.inspectors = {'test-inspector'}
      inspect.inspect(buffer)
      assert.spy(inspector).was_called_with(buffer)

    it 'runs inspectors specified for the mode', ->
      buffer.mode.config.inspectors = {'test-inspector'}
      inspect.inspect(buffer)
      assert.spy(inspector).was_called_with(buffer)

    it 'merges inspection results into one scathing result', ->
      inspection.register name: 'inspector1', factory: ->
        -> { { line: 1, type: 'error', message: 'foo' } }

      inspection.register name: 'inspector2', factory: ->
        -> {
          { line: 1, type: 'error', message: 'foo_mode' }
          { line: 3, type: 'warning', message: 'bar' }
        }

      buffer.config.inspectors = {'inspector1', 'inspector2'}
      res = inspect.inspect(buffer)
      assert.same {
        [1]: {
          { type: 'error', message: 'foo' },
          { type: 'error', message: 'foo_mode' }
        }
        [3]: {
          { type: 'warning', message: 'bar' }
        }
       }, res

  describe 'criticize(buffer, criticism)', ->
    before_each ->
      buffer.text = 'linƏ 1\nline 2\nline 3'

    it 'applies inspect markers to the buffer corresponding to criticisms', ->
      inspect.criticize buffer, {
        [1]: {
          {type: 'error', message: 'bar'}
        },
        [2]: {
          {type: 'error', message: 'zed'}
        }
       }
      assert.same {
        {
          start_offset: 1,
          end_offset: 7,
          name: 'inspection',
          flair: 'error',
          message: 'bar'
        },
        {
          start_offset: 8,
          end_offset: 14,
          name: 'inspection',
          flair: 'error',
          message: 'zed'
        }
      }, buffer.markers.all

    it 'starts the visual marker at the start of text for line inspections', ->
      buffer.text = '  34567\n'
      inspect.criticize buffer, {
        [1]: {
          {type: 'error', message: 'zed'}
        }
      }
      assert.equal 3, buffer.markers.all[1].start_offset

    describe 'when a .search field is present', ->
      it 'is used for selecting a part of the line to highlight', ->
        buffer.text = '1 345 7\n'
        inspect.criticize buffer, {
          [1]: {
            {type: 'error', message: 'zed', search: '345'}
          }
        }
        marker = buffer.markers.all[1]
        assert.equal 3, marker.start_offset
        assert.equal 6, marker.end_offset

      it 'marks the whole line if the search fails', ->
        buffer.text = '1234567\n'
        inspect.criticize buffer, {
          [1]: {
            {type: 'error', message: 'zed', search: 'XX'}
          }
        }
        marker = buffer.markers.all[1]
        assert.equal 1, marker.start_offset
        assert.equal 8, marker.end_offset

      it 'marks the whole line if the search has multiple matches ', ->
        buffer.text = 'foo foo\n'
        inspect.criticize buffer, {
          [1]: {
            {type: 'error', message: 'zed', search: 'oo'}
          }
        }
        marker = buffer.markers.all[1]
        assert.equal 1, marker.start_offset
        assert.equal 8, marker.end_offset

      it 'is not confused by other substring matches', ->
        buffer.text = ' res = refresh!\n'
        inspect.criticize buffer, {
          [1]: {
            {type: 'error', message: 'zed', search: 'res'}
          }
        }
        marker = buffer.markers.all[1]
        assert.equal 2, marker.start_offset
        assert.equal 5, marker.end_offset
