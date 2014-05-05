glib = require 'ljglibs.glib'

describe 'glib', ->

  describe 'version management', ->
    it 'provides version numbers', ->
      assert.equals 'number', type glib.major_version
      assert.equals 'number', type glib.minor_version
      assert.equals 'number', type glib.micro_version

    describe 'check_version(major, minor, micro)', ->
      it 'returns true if the current version meets the requirements', ->
        assert.is_true glib.check_version glib.major_version, glib.minor_version, glib.micro_version
        unless glib.minor_version == 0
          assert.is_true glib.check_version glib.major_version, glib.minor_version - 1, glib.micro_version

      it 'returns false and an error string if the current version fails the requirements', ->
        res = { glib.check_version glib.major_version + 1, glib.minor_version, glib.micro_version }
        assert.is_false res[1]
        assert.equals 'string', type res[2]
