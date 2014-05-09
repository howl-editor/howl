-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

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
      with_stream (p, f) ->
        f\write_all 'foobar'
        f\close!
        assert.equals 'foobar', File(p)\load_contents!

  describe 'write_async(data, count, handler)', ->
    it 'invokes the handler with the status and the number of bytes written', (done) ->
      with_stream (p, f) ->
        f\write_async 'foobar', nil, async (status, written) ->
          assert.is_true status
          assert.equals 'number', type(written)
          done!
