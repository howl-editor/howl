import config, signal from howl
import theme from howl.ui
import File from howl.io
Gtk = require 'ljglibs.gtk'

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
    background: 'blue'

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
    popup: {}
}

theme_copy = ->
  dumped = serpent.dump spec_theme
  loadstring(dumped)!

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

  describe 'assigning a new theme to config.theme', ->
    it "logs an error if there's an error loading the theme", ->
      File.with_tmpfile (file) ->
        file.contents = "error('cantload')"
        theme.register 'error', file
        config.theme = 'error'
        assert.match log.last_error.message, 'cantload'

    it "assigns the loaded theme to .current and sets .name", ->
      File.with_tmpfile (file) ->
        file.contents = serpent.dump spec_theme
        theme.register 'foo', file
        config.theme = 'foo'
        expected = theme_copy!
        expected.name = 'foo'
        assert.same theme.current, expected

    it 'emits a theme-changed event with the newly set theme', ->
      File.with_tmpfile (file) ->
        file.contents = serpent.dump spec_theme
        theme.register 'alert', file
        handler = spy.new -> true
        signal.connect 'theme-changed', handler
        config.theme = 'alert'
        signal.disconnect 'theme-changed', handler
        expected = theme_copy!
        expected.name = 'alert'
        assert.spy(handler).was_called_with theme: expected

    it 'does not propagate global assignments to the global environment', ->
      File.with_tmpfile (file) ->
        file.contents = 'spec_global = "noo!"\n' .. serpent.dump spec_theme
        theme.register 'foo', file
        config.theme = 'foo'
        assert.is_nil spec_global

    it 'allows the use of named colors', ->
      File.with_tmpfile (file) ->
        theme_string = serpent.dump spec_theme
        theme_string = theme_string\gsub '"#777777"', 'violet' -- footer.color
        file.contents = theme_string
        theme.register 'colors', file
        config.theme = 'colors'
        assert.equal theme.current.editor.footer.color, '#ee82ee'

  it 'assigning directly to .current raises an error', ->
    File.with_tmpfile (file) ->
      file.contents = serpent.dump spec_theme
      theme.register 'foo', file
      assert.has_errors -> config.current = 'foo'

  describe 'widget background support', ->

    set_theme_with_background = (color, style = 'default') ->
      File.with_tmpfile (file) ->
        the_theme = theme_copy!
        the_theme.styles[style].background = color
        file.contents = serpent.dump the_theme
        theme.register 'with_background', file
        config.theme = 'with_background'

    describe 'register_background_widget(widget, style)', ->

      it "overrides the widget's background with the current theme background", ->
        widget = Gtk.EventBox!
        set_theme_with_background 'red'
        theme.register_background_widget widget
        bg = widget.style_context\get_background_color Gtk.STATE_FLAG_NORMAL
        assert.same { 1, 0, 0 }, { bg.red, bg.green, bg.blue }

      it "updates the widget's background whenever the theme changes", ->
        widget = Gtk.EventBox!
        set_theme_with_background 'red'
        theme.register_background_widget widget
        set_theme_with_background 'blue'
        bg = widget.style_context\get_background_color Gtk.STATE_FLAG_NORMAL
        assert.same { 0, 0, 1 }, { bg.red, bg.green, bg.blue }

      context 'when <style> is specified', ->
        it 'uses the named style for the background if possible', ->
          widget = Gtk.EventBox!
          set_theme_with_background '#00ff00', 'popup'
          theme.register_background_widget widget, 'popup'
          bg = widget.style_context\get_background_color Gtk.STATE_FLAG_NORMAL
          assert.same { 0, 1, 0 }, { bg.red, bg.green, bg.blue }

        it 'falls back to the default style if the specified style is unavailable', ->
          widget = Gtk.EventBox!
          set_theme_with_background 'red'
          theme.register_background_widget widget, 'popup'
          bg = widget.style_context\get_background_color Gtk.STATE_FLAG_NORMAL
          assert.same { 1, 0, 0 }, { bg.red, bg.green, bg.blue }

    describe 'unregister_background_widget(widget)', ->
      it 'causes the widget to be excluded from theme auto-updates', ->
        widget = Gtk.EventBox!
        set_theme_with_background 'red'
        theme.register_background_widget widget
        theme.unregister_background_widget widget
        set_theme_with_background 'blue'
        bg = widget.style_context\get_background_color Gtk.STATE_FLAG_NORMAL
        assert.same { 1, 0, 0 }, { bg.red, bg.green, bg.blue }

  describe 'life cycle management', ->
    it 'automatically applies a theme upon registration if that theme is already set as current', ->
      File.with_tmpfile (file) ->
        the_theme = theme_copy!
        file.contents = serpent.dump the_theme
        theme.register 'reloadme', file
        config.theme = 'reloadme'

        theme.unregister 'reloadme'
        the_theme.window.background = '#112233'
        file.contents = serpent.dump the_theme
        theme.register 'reloadme', file
        assert.equal '#112233', theme.current.window.background

    it 'keeps the loaded in-memory theme when the current is unregistered', ->
      File.with_tmpfile (file) ->
        file.contents = serpent.dump spec_theme
        theme.register 'keepme', file
        config.theme = 'keepme'
        theme.unregister 'keepme'
        assert.equal 'keepme', theme.current.name
