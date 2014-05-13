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
