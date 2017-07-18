-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

glib = require 'ljglibs.glib'
{:File} = require 'ljglibs.gio'

with_tmpfile = (contents, f) ->
  p = os.tmpname!
  if jit.os == 'Windows'
    p = p\sub 2
  fh = io.open p, 'wb'
  fh\write contents
  fh\close!
  status, err = pcall f, p
  os.remove p
  error err unless status

with_stream_for = (contents, f) ->
  with_tmpfile contents, (p) ->
    f File(p)\read!

describe 'InputStream', ->
  setup -> set_howl_loop!

  describe 'read(count)', ->
    it 'reads up to <count> bytes or to EOF', ->
      with_stream_for "foobar", (stream) ->
        -- for files all will be read
        assert.same 'foo', stream\read 3
        assert.same 'bar', stream\read 10

    it 'returns nil upon EOF', ->
      with_stream_for "foobar", (stream) ->
        stream\read_all 10
        assert.is_nil stream\read!

  describe 'read_all(count)', ->
    it 'reads <count> bytes or to EOF', ->
      with_stream_for "foobar", (stream) ->
        assert.same 'foo', stream\read_all 3
        assert.same 'bar', stream\read_all 10

    it 'returns nil upon EOF', ->
      with_stream_for "foobar", (stream) ->
        stream\read_all 10
        assert.is_nil stream\read_all!

  describe 'read_async(count, priority, handler)', ->
    it 'invokes the handler with the status and up to <count> bytes read', (done) ->
      with_stream_for "foobar", (stream) ->
        stream\read_async 3, glib.PRIORITY_LOW, async (status, buf) ->
          assert.is_true status
          assert.same 'foo', buf
          done!

    it 'reads up to EOF', (done) ->
      with_stream_for "foobar", (stream) ->
        stream\read_async 10, glib.PRIORITY_LOW, async (status, buf) ->
          assert.is_true status
          assert.same 'foobar', buf
          done!

    it 'passes <true, nil> when at EOF', (done) ->
      with_stream_for "foobar", (stream) ->
        stream\read_all!
        stream\read_async 10, glib.PRIORITY_LOW, async (status, buf) ->
          assert.is_true status
          assert.is_nil buf
          done!

  describe 'close_async(handler)', ->
    it 'invokes the handler with the status and any eventual error message', (done) ->
      with_stream_for "foobar", (stream) ->
        stream\close_async async (status, err) ->
          assert.is_true status
          assert.is_nil err
          done!

  describe '.is_closed', ->
    it 'is true when the stream is closed and false otherwise', ->
      with_stream_for "foobar", (stream) ->
        assert.is_false stream.is_closed
        stream\close!
        assert.is_true stream.is_closed
