import theme from howl.ui
import File from howl.fs

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

  styles:
    default: background: 'blue'
}

describe 'theme', ->
  describe 'register(name, file)', ->
    it "adds name to .all", ->
      file = File 'test'
      theme.register 'test', file
      assert.equal theme.all.test, file

    it 'raises an error if name is omitted', ->
      status, msg = pcall theme.register, nil, File 'foo'
      assert.is_false(status)
      assert.match msg, 'name'

    it 'raises an error if file is omitted', ->
      status, msg = pcall theme.register, 'test'
      assert.is_false(status)
      assert.match msg, 'file'

  describe 'unregister(name)', ->
    it 'removes the theme from all', ->
      file = File 'tmp'
      theme.register 'tmp', file
      theme.unregister 'tmp'
      assert.is_nil theme.all.tmp

  describe 'assigning to .current', ->
    it "raises an error if there's an error loading the theme", ->
      with_tmpfile (file) ->
        file.contents = "error('cantload')"
        theme.register 'error', file
        assert.error -> theme.current = 'error'

    it "assigns the loaded theme to .current and sets .name", ->
      with_tmpfile (file) ->
        file.contents = serpent.dump spec_theme
        theme.register 'foo', file
        theme.current = 'foo'
        expected = moon.copy spec_theme
        expected.name = 'foo'
        assert.same theme.current, expected

    it 'does not propagate global assignments to the global environment', ->
      with_tmpfile (file) ->
        file.contents = 'spec_global = "noo!"\n' .. serpent.dump spec_theme
        theme.register 'foo', file
        theme.current = 'foo'
        assert.is_nil spec_global

    it 'allows the use of named colors', ->
      with_tmpfile (file) ->
        theme_string = serpent.dump spec_theme
        theme_string = theme_string\gsub '"#777777"', 'violet' -- footer.color
        file.contents = theme_string
        theme.register 'colors', file
        theme.current = 'colors'
        assert.equal theme.current.editor.footer.color, '#ee82ee'

    describe 'apply()', ->
      it 'raises an error unless the current theme is set', ->
        theme.current = nil
        assert.has_error -> theme.apply!

      it 'does not raise an error when applying a valid theme', ->
        with_tmpfile (file) ->
          file.contents = serpent.dump spec_theme
          theme.register 'foo', file
          theme.current = 'foo'

        theme.apply!
