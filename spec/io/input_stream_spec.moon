{:InputStream, :File} = howl.io
GFile = require 'ljglibs.gio.file'

describe 'InputStream', ->

  with_stream_for = (contents, cb) ->
    howl_async ->
      File.with_tmpfile (f) ->
        f.contents = contents
        cb InputStream GFile(f.path)\read!

  describe 'read(num)', ->
    it 'reads up to <num> bytes from the stream', (done) ->
      with_stream_for 'foobar', (stream) ->
        assert.equal 'foo', stream\read 3
        assert.equal 'bar', stream\read 10
        assert.is_nil stream\read 10
        done!

  describe 'read_async(num, handler)', ->
    it 'invokes <handler> with the status and up to <num> bytes read from the stream', (done) ->
      with_stream_for 'foobar', (stream) ->
        handler = (status, read) ->
          assert.is_true status
          assert.equal 'foobar', read
          done!

        stream\read_async 10, handler

    it 'invokes <handler> with true and nil upon EOF', (done) ->
      with_stream_for 'foobar', (stream) ->
        handler = (status, read) ->
          assert.is_true status
          assert.is_nil read
          done!

        stream\read 10
        stream\read_async 10, handler

  describe 'read_all()', ->
    it 'reads all the streams content in one go', (done) ->
      content = string.rep 'This is my line of text. Rinse, wash and repeat', 500, '\n'
      with_stream_for content, (stream) ->
        read = stream\read_all!
        assert.equal #content, #read
        assert.equal content, read
        assert.is_nil stream\read 10
        done!

  describe 'close', ->
    it 'closes the stream', (done) ->
      with_stream_for 'foobar', (stream) ->
        assert.is_false stream.is_closed
        stream\close!
        assert.is_true stream.is_closed
        done!
