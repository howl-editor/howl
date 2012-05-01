import theme from vilu.ui
import File from vilu.fs

describe 'theme', ->
  describe '.load', ->
    context 'when given a table', ->

      it 'raises an error if .name is not specified', ->
        status, msg = pcall theme.load, {}
        assert_false(status)
        assert_match('.*%.name.*', msg)

      it "assigns the loaded theme to .available using it's name", ->
        theme.load name: 'foo'
        assert_not_nil theme.available.foo

    context 'when given a file', ->
      it 'loads the theme from the specified file', ->
        tmpfile = File.tmpfile!
        tmpfile.contents = [[
          return {
            name = 'bar'
          }
        ]]
        assert pcall theme.load, tmpfile
        tmpfile\delete!
        assert_not_nil theme.available.bar
