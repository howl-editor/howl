-- Copyright 2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
GLib = require 'ljglibs.glib'
MappedFile = GLib.MappedFile

with_tmpfile = (f) ->
  p = os.tmpname!
  status, err = pcall f, p
  os.remove p
  error err unless status

describe 'MappedFile', ->
  describe 'MappedFile(path, writable)', ->
    it 'raises an error when <path> cannot be opened', ->
      assert.raises "nofilehere", ->  MappedFile '/nononononononofilehere'
      assert.raises "/bin", ->  MappedFile '/bin'

    it '.length and #MappedFile returns the length of the mapped file', ->
      with_tmpfile (path) ->
        f = assert io.open(path, 'w+')
        f\write '12345'
        assert f\close!
        mf = MappedFile path
        assert.equals 5, mf.length
        assert.equals 5, #mf

    it '.contents is a char pointer to the contents of the file', ->
      with_tmpfile (path) ->
        f = assert io.open(path, 'w+')
        f\write '12345'
        assert f\close!
        mf = MappedFile path
        contents = mf.contents
        print contents[0]
        assert.equals 0x31, contents[0]
        assert.equals 0x31 + 1, contents[1]
        assert.equals 0x31 + 2, contents[2]
        assert.equals 0x31 + 3, contents[3]
        assert.equals 0x31 + 4, contents[4]
