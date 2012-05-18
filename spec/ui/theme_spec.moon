import theme from vilu.ui
import File from vilu.fs

describe 'theme', ->
  describe '.register(name, file)', ->
    it "adds name to .available", ->
      file = File 'test'
      theme.register 'test', file
      assert_match 'test', table.concat(theme.available, '|')

    it 'raises an error if name is omitted', ->
      status, msg = pcall theme.register, nil, File 'foo'
      assert_false(status)
      assert_match('name', msg)

    it 'raises an error if file is omitted', ->
      status, msg = pcall theme.register, 'test'
      assert_false(status)
      assert_match('file', msg)

    describe 'assigning to .current', ->
      it "raises an error if there's an error loading the theme", ->
        tmpfile = File.tmpfile!
        tmpfile.contents = "error('cantload')"
        theme.register 'error', tmpfile
        assert_error ->
          theme.current = 'error'
