-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:File, :FileOutputStream} = require 'ljglibs.gio'

with_tmpfile = (f) ->
  p = os.tmpname!
  status, err = pcall f, p
  os.remove p
  error err unless status

with_stream = (f) ->
  with_tmpfile (p) ->
    f p, File(p)\append_to!

describe 'OutputStream', ->
  setup -> set_howl_loop!

  describe 'write(contents)', ->
    it 'writes the contents to the file', ->
      with_stream (p, stream) ->
        stream\write_all 'foobar'
        stream\close!
        assert.equals 'foobar', File(p)\load_contents!

  describe 'write_async(data, count, handler)', ->
    it 'invokes the handler with the status and the number of bytes written', (done) ->
      with_stream (p, stream) ->
        stream\write_async 'foobar', nil, async (status, written) ->
          assert.is_true status
          assert.equals 'number', type(written)
          done!

  describe 'close_async(handler)', ->
    it 'invokes the handler with the status and any eventual error message', (done) ->
      with_stream (p, stream) ->
        stream\close_async async (status, err) ->
          assert.is_true status
          assert.is_nil err
          done!

  describe '.is_closed', ->
    it 'is true when the stream is closed and false otherwise', ->
      with_stream (p, stream) ->
        assert.is_false stream.is_closed
        stream\close!
        assert.is_true stream.is_closed
