-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

{:File, :FileInputStream} = require 'ljglibs.gio'

with_tmpfile = (contents, f) ->
  p = os.tmpname!
  fh = io.open p, 'w'
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

  describe 'read_async(count, handler)', ->
    it 'invokes the handler with the status and up to <count> bytes read', (done) ->
      with_stream_for "foobar", (stream) ->
        stream\read_async 3, async (status, buf) ->
          assert.is_true status
          assert.same 'foo', buf
          done!

    it 'reads up to EOF', (done) ->
      with_stream_for "foobar", (stream) ->
        stream\read_async 10, async (status, buf) ->
          assert.is_true status
          assert.same 'foobar', buf
          done!

    it 'passes <true, nil> when at EOF', (done) ->
      with_stream_for "foobar", (stream) ->
        stream\read_all!
        stream\read_async 10, async (status, buf) ->
          assert.is_true status
          assert.is_nil buf
          done!
