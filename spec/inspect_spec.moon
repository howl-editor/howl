-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import inspect, inspection, Buffer, mode from howl
File = howl.io.File
match = require 'luassert.match'

describe 'inspect', ->
  local buffer, idle_inspector, save_inspector

  before_each ->
    mode.register name: 'inspect-mode', create: -> {}
    idle_inspector = spy.new -> {}
    save_inspector = spy.new -> {}
    inspection.register name: 'test-idle-inspector', factory: -> idle_inspector
    inspection.register name: 'test-save-inspector', factory: -> save_inspector
    buffer = Buffer mode.by_name('inspect-mode')

  after_each ->
    mode.unregister 'inspect-mode'
    inspection.unregister 'test-idle-inspector'
    inspection.unregister 'test-save-inspector'

  describe 'inspect(buffer, scope)', ->
    it 'runs inspectors specified for the buffer', ->
      buffer.config.inspectors_on_idle = {'test-idle-inspector'}
      inspect.inspect(buffer)
      assert.spy(idle_inspector).was_called_with(match.is_ref(buffer))

    it 'runs inspectors specified for the mode', ->
      buffer.mode.config.inspectors_on_idle = {'test-idle-inspector'}
      inspect.inspect(buffer)
      assert.spy(idle_inspector).was_called_with(match.is_ref(buffer))

    context 'inspector types', ->
      before_each ->
        with buffer.mode.config
          .inspectors_on_idle = {'test-idle-inspector'}
          .inspectors_on_save = {'test-save-inspector'}

      it 'runs both idle and save inspectors by default', ->
        inspect.inspect(buffer)
        assert.spy(idle_inspector).was_called_with(match.is_ref(buffer))
        assert.spy(save_inspector).was_called_with(match.is_ref(buffer))

      it 'runs only idle inspectors if specified', ->
        inspect.inspect(buffer, scope: 'idle')
        assert.spy(idle_inspector).was_called_with(match.is_ref(buffer))
        assert.spy(save_inspector).was_not_called!

      it 'runs only save inspectors if specified', ->
        inspect.inspect(buffer, scope: 'save')
        assert.spy(save_inspector).was_called_with(match.is_ref(buffer))
        assert.spy(idle_inspector).was_not_called!

    context 'when the returned inspector is a string', ->
      it 'is run as an external command, translating default output parsing', (done) ->
        idle_inspector = 'echo "foo:1: warning: foo\nline 2: wrong val \\`foo\\`"'
        howl_async ->
          buffer.mode.config.inspectors_on_idle = {'test-idle-inspector'}
          res = inspect.inspect(buffer)
          assert.same {
            [1]: {
              { message: 'warning: foo', type: 'warning' },
            }
            [2]: {
              { message: 'wrong val `foo`', search: 'foo' }
            }
           }, res
          done!

    context 'when the returned inspector is a table', ->
      it 'uses the `cmd` key as the external command to run', (done) ->
        idle_inspector = cmd: 'echo "foo:1: some warning"'
        howl_async ->
          buffer.mode.config.inspectors_on_idle = {'test-idle-inspector'}
          res = inspect.inspect(buffer)
          assert.same {
            [1]: {
              { message: 'some warning' },
            }
           }, res
          done!

      it 'allows for custom parsing via the `parse` key', (done) ->
        idle_inspector = {
          cmd: 'echo "output"'
          parse: spy.new -> { {line: 1, message: 'foo' } }
        }
        howl_async ->
          buffer.mode.config.inspectors_on_idle = {'test-idle-inspector'}
          res = inspect.inspect(buffer)
          assert.spy(idle_inspector.parse).was_called_with('output\n')
          assert.same {
            [1]: {
              { message: 'foo' },
            }
           }, res
          done!

      it 'allows for custom post processing via the `post_parse` key', (done) ->
        idle_inspector = {
          cmd: 'echo "foo:1: some warning"'
          post_parse: (inspections) -> inspections[1].search = 'zed'
        }
        howl_async ->
          buffer.mode.config.inspectors_on_idle = {'test-idle-inspector'}
          res = inspect.inspect(buffer)
          assert.same {
            [1]: {
              { message: 'some warning', search: 'zed' },
            }
           }, res
          done!

      it 'allows for specifying the type of inspections via the `type` key', (done) ->
        idle_inspector = cmd: 'echo "foo:1: some warning"', type: 'warning'
        howl_async ->
          buffer.mode.config.inspectors_on_idle = {'test-idle-inspector'}
          res = inspect.inspect(buffer)
          assert.same {
            [1]: {
              { message: 'some warning', type: 'warning' },
            }
           }, res
          done!

      it 'skips unavailable inspectors', (done) ->
        idle_inspector = {
          cmd: 'echo "foo:1: some warning"',
          is_available: -> false
        }
        howl_async ->
          buffer.mode.config.inspectors_on_idle = {'test-idle-inspector'}
          res = inspect.inspect(buffer)
          assert.same {}, res
          done!

    context 'when an inspector command contains a <file> placeholder', ->
      it "is skipped if the buffer has no associated file", (done) ->
        buffer.modified = false
        idle_inspector = 'echo "foo:1: <file> urk"'
        howl_async ->
          buffer.mode.config.inspectors_on_idle = {'test-idle-inspector'}
          assert.same {}, inspect.inspect(buffer)
          done!

      it "is skipped if the buffer is modified", (done) ->
        file = File '/foo/bar'
        buffer.file = file
        buffer.modified = true
        idle_inspector = 'echo "foo:1: <file> urk"'
        howl_async ->
          buffer.mode.config.inspectors_on_idle = {'test-idle-inspector'}
          assert.same {}, inspect.inspect(buffer)
          done!

      it "is expanded with the buffer's file's path", (done) ->
        file = File '/foo/bar'
        buffer.file = file
        idle_inspector = cmd: 'echo "foo:1: <file>"'
        howl_async ->
          buffer.mode.config.inspectors_on_idle = {'test-idle-inspector'}
          res = inspect.inspect(buffer)
          assert.same {
            [1]: {
              { message: '/foo/bar' },
            }
          }, res
          done!

      it 'is not passed the buffer content on stdin', (done) ->
        file = File '/foo/bar'
        buffer.file = file
        buffer.text = 'bar:1: mem'
        buffer.modified = false
        idle_inspector = cmd: 'cat <file> -'
        howl_async ->
          buffer.mode.config.inspectors_on_idle = {'test-idle-inspector'}
          res = inspect.inspect(buffer)
          assert.same {}, res
          done!

    it 'merges inspection results into one scathing result', ->
      inspection.register name: 'inspector1', factory: ->
        -> { { line: 1, type: 'error', message: 'foo' } }

      inspection.register name: 'inspector2', factory: ->
        -> {
          { line: 1, type: 'error', message: 'foo_mode' }
          { line: 3, type: 'warning', message: 'bar' }
        }

      buffer.config.inspectors_on_idle = {'inspector1', 'inspector2'}
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

  describe 'criticize(buffer, criticism, opts)', ->
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

    it 'leaves previous inspection markers alone by default', ->
      inspect.criticize buffer, {
        [1]: { {type: 'error', message: 'bar'} }
      }

      inspect.criticize buffer, {
        [2]: { {type: 'error', message: 'zed'} }
      }

      assert.equal 2, #buffer.markers.all

    it 'clears previous inspection markers when opts.clear is set', ->
      inspect.criticize buffer, {
        [1]: { {type: 'error', message: 'bar'} }
      }

      inspect.criticize buffer, {
        [2]: { {type: 'error', message: 'zed'} }
      }, clear: true

      assert.equal 1, #buffer.markers.all
      assert.equal 8, buffer.markers.all[1].start_offset

    it 'starts the visual marker at the start of text for line inspections', ->
      buffer.text = '  34567\n'
      inspect.criticize buffer, {
        [1]: {
          {type: 'error', message: 'zed'}
        }
      }
      assert.equal 3, buffer.markers.all[1].start_offset

    it 'starts the visual marker at the unicode pos given by .start_col if present', ->
      buffer.text = 'åäö\n'
      inspect.criticize buffer, {
        [1]: {
          {type: 'error', message: 'zed', start_col: 2}
        }
      }
      assert.equal 2, buffer.markers.all[1].start_offset

    it 'ends the visual marker at the unicode pos given by .end_col if present', ->
      buffer.text = 'åäö\n'
      inspect.criticize buffer, {
        [1]: {
          {type: 'error', message: 'zed', end_col: 3}
        }
      }
      assert.equal 3, buffer.markers.all[1].end_offset

    it 'starts the visual marker at the byte offset given by .byte_start_col if present', ->
      buffer.text = 'åäö\n'
      inspect.criticize buffer, {
        [1]: {
          {type: 'error', message: 'zed', byte_start_col: 3}
        }
      }
      assert.equal 2, buffer.markers.all[1].start_offset

    it 'ends the visual marker at the byte offset given by .byte_end_col if present', ->
      buffer.text = 'åäö\n'
      inspect.criticize buffer, {
        [1]: {
          {type: 'error', message: 'zed', byte_end_col: 3}
        }
      }
      assert.equal 2, buffer.markers.all[1].end_offset

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
