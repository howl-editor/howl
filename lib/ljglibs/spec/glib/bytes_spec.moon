ffi = require 'ffi'
GLib = require 'ljglibs.glib'

Bytes = GLib.Bytes

describe 'Bytes', ->

  describe 'creation', ->
    it 'can be created from a string', ->
      bytes = Bytes 'hello'
      assert.not_nil bytes
      assert.equals 5, bytes.size
      assert.equals 'hello', bytes.data

    it 'can be created from cdata if size is provided', ->
      s = 'world'
      cdata_s = ffi.cast 'const char *', s
      bytes = Bytes cdata_s, #s
      assert.not_nil bytes
      assert.equals 5, bytes.size
      assert.equals 'world', bytes.data

  describe '#bytes returns the size of the data', ->
    assert.equals 4, #Bytes('w00t')
