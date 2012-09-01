import theme from lunar.ui
import File from lunar.fs

serpent = require 'serpent'

font = name: 'Liberation Mono', size: 11, bold: true

spec_theme = {
  window:
    background: '#000000'
    status:
      :font
      color: '#0000ff'

  editor:
    border_color: '#000000'
    divider_color: '#000000'

    header:
      background: '#000000'
      color: 'darkgrey'
      :font

    footer:
      background: '#dddddd'
      color: '#777777'
      :font

    indicators:
      title: :font

  styles: {}
}

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
        with_tmpfile (file) ->
          file.contents = "error('cantload')"
          theme.register 'error', file
          assert_error -> theme.current = 'error'

      it "assigns the loaded theme to .current and sets .name", ->
        with_tmpfile (file) ->
          file.contents = serpent.dump spec_theme
          theme.register 'foo', file
          theme.current = 'foo'
          expected = moon.copy spec_theme
          expected.name = 'foo'
          assert_table_equal theme.current, expected

      it 'does not propagate global assignments to the global environment', ->
        with_tmpfile (file) ->
          file.contents = 'spec_global = "noo!"\n' .. serpent.dump spec_theme
          theme.register 'foo', file
          theme.current = 'foo'
          assert_nil spec_global

      it 'allows the use of named colors', ->
        with_tmpfile (file) ->
          theme_string = serpent.dump spec_theme
          theme_string = theme_string\gsub '"#777777"', 'violet' -- footer.color
          file.contents = theme_string
          theme.register 'colors', file
          theme.current = 'colors'
          assert_equal theme.current.editor.footer.color, '#ee82ee'
