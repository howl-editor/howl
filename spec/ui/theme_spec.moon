import theme from vilu.ui
import File from vilu.fs

describe 'theme', ->
  describe '.load', ->
    context 'when given a file', ->
      it 'raises an error if .name is not specified', ->
        tmpfile = File.tmpfile!
        tmpfile.contents = 'return {}'
        status, msg = pcall theme.load, tmpfile
        tmpfile\delete!
        assert_false(status)
        assert_match('.*%.name.*', msg)

      it "assigns the loaded theme to .available using it's name", ->
        tmpfile = File.tmpfile!
        tmpfile.contents = [[
          return {
            name = 'bar'
          }
        ]]
        assert pcall theme.load, tmpfile
        tmpfile\delete!
        assert_not_nil theme.available.bar
