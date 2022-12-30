import config from howl
import theme from howl.ui
import File from howl.io

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
        file.contents = "cantload!"
        theme.register 'error', file
        config.theme = 'error'
        assert.match log.last_error.message, 'Theme error'

    it "assigns the loaded theme to .current and sets .name", ->
      File.with_tmpfile (file) ->
        -- file.contents = serpent.dump spec_theme
        theme.register 'foo', file
        config.theme = 'foo'
        -- expected = theme_copy!
        -- expected.name = 'foo'
        assert.equal 'foo', theme.current.name
        -- assert.same theme.current, expected

    -- it 'emits a theme-changed event with the newly set theme', ->
    --   File.with_tmpfile (file) ->
    --     file.contents = serpent.dump spec_theme
    --     theme.register 'alert', file
    --     handler = spy.new -> true
    --     signal.connect 'theme-changed', handler
    --     config.theme = 'alert'
    --     signal.disconnect 'theme-changed', handler
    --     expected = theme_copy!
    --     expected.name = 'alert'
    --     assert.spy(handler).was_called_with theme: expected

    -- it 'does not propagate global assignments to the global environment', ->
    --   File.with_tmpfile (file) ->
    --     file.contents = 'spec_global = "noo!"\n' .. serpent.dump spec_theme
    --     theme.register 'foo', file
    --     config.theme = 'foo'
    --     assert.is_nil _G.spec_global

    -- it 'allows the use of named colors', ->
    --   File.with_tmpfile (file) ->
    --     theme_string = serpent.dump spec_theme
    --     theme_string = theme_string\gsub '"#777777"', 'violet' -- footer.color
    --     file.contents = theme_string
    --     theme.register 'colors', file
    --     config.theme = 'colors'
    --     assert.equal theme.current.editor.footer.color, '#ee82ee'

  it 'assigning directly to .current raises an error', ->
    File.with_tmpfile (file) ->
      theme.register 'foo', file
      assert.has_errors -> config.current = 'foo'

  context 'style parsing', ->
    load_css = (css) ->
      File.with_tmpfile (file) ->
        file.contents = css
        theme.register 'styles', file
        config.theme = 'styles'
        theme.current.styles

    it 'parses style declarations into the internal style format', ->
      assert.equal 'red', load_css('style.foo { color: red; }').foo.color

    it 'underscores the style names', ->
      assert.equal 'red', load_css('style.foo-bar { color: red; }').foo_bar.color

    it 'disregards comments from the declarations', ->
      assert.equal 'red', load_css([[
        style.foo {
          /* what: never mind me */
          color: red;
        }
      ]]).foo.color

    it 'translates font-style: italic as font.italic', ->
      assert.same {
        foo: {
          font: italic: true
        }
      }, load_css 'style.foo { font-style: italic; }'

    it 'translates font-weight: bold as font.bold', ->
      assert.same {
        foo: {
          font: bold: true
        }
      }, load_css 'style.foo { font-weight: bold; }'

    it 'translates font-size font.size', ->
      assert.same {
        foo: {
          font: size: 'urk'
        }
      }, load_css 'style.foo { font-size: urk; }'

    it 'translates font-family as font.family', ->
      assert.same {
        foo: {
          font: family: 'monospace'
        }
      }, load_css 'style.foo { font-family: monospace; }'

    it 'translates color as color', ->
      assert.equals 'green', load_css('style.foo { color: green; }').foo.color

    it 'translates background-color as background', ->
      assert.equals 'green', load_css(
        'style.foo { background-color: green; }'
      ).foo.background

    it 'allows alpha values for background-color', ->
      assert.equals '#dddddd70', load_css(
        'style.foo { background-color: #dddddd70; }'
      ).foo.background

    it 'implements the Gtk alpha function', ->
      assert.equals '#00ff007f', load_css(
        'style.foo { color: alpha(#00ff00, 0.5); }'
      ).foo.color

    it 'handles color names for the Gtk alpha function', ->
      assert.equals '#0000007f', load_css(
        'style.foo { color: alpha(black, 0.5); }'
      ).foo.color

    it 'translates text-decoration underline as underline', ->
      assert.is_true load_css(
        'style.foo { text-decoration: underline; }'
      ).foo.underline

    it 'translates text-decoration line-through as strike_through', ->
      assert.is_true load_css(
        'style.foo { text-decoration: line-through; }'
      ).foo.strike_through

  context 'flair parsing', ->
    load_css = (css) ->
      File.with_tmpfile (file) ->
        file.contents = css
        theme.register 'flairs', file
        config.theme = 'flairs'
        theme.current.flairs

    it 'parses flairs declarations into the internal flairs format', ->
      assert.same {
        type: 'pipe',
        foreground: 'red'
      }, load_css('flair.foo { shape: pipe; border-color: red; }').foo

    it 'underscores the style names', ->
      assert.equal 'red', load_css(
        'flair.foo-bar { shape: pipe; border-color: red; }'
      ).foo_bar.foreground

    it 'translates width as line_width ', ->
      assert.equal 2, load_css(
        'flair.foo { shape: pipe; border-color: red; width: 2; }'
      ).foo.line_width

    it 'translates minimum-width as min_width ', ->
      assert.equal 2, load_css(
        'flair.foo { shape: pipe; minimum-width: 2; }'
      ).foo.min_width

    it 'translates color as text_color ', ->
      assert.equal 'red', load_css(
        'flair.foo { shape: pipe; color: red; }'
      ).foo.text_color

    it 'translates background-color as background ', ->
      assert.equal 'red', load_css(
        'flair.foo { shape: pipe; background-color: red; }'
      ).foo.background

    it 'translates border-radius as corner_radius ', ->
      assert.equal 2, load_css(
        'flair.foo { shape: rounded-rectangle; border-radius: 2; }'
      ).foo.corner_radius

  context 'custom value extractions', ->
    load_css = (css) ->
      File.with_tmpfile (file) ->
        file.contents = css
        theme.register 'custom', file
        config.theme = 'custom'
        theme.current.custom

    it 'extracts .gutter color as gutter_color', ->
      assert.equal 'red', load_css(
        '.gutter { color: red; }'
      ).gutter_color


  -- describe 'life cycle management', ->
    -- it 'automatically applies a theme upon registration if that theme is already set as current', ->
    --   File.with_tmpfile (file) ->
    --     the_theme = theme_copy!
    --     file.contents = serpent.dump the_theme
    --     theme.register 'reloadme', file
    --     config.theme = 'reloadme'

    --     theme.unregister 'reloadme'
    --     the_theme.window.background = '#112233'
    --     file.contents = serpent.dump the_theme
    --     theme.register 'reloadme', file
    --     assert.equal '#112233', theme.current.window.background

    -- it 'keeps the loaded in-memory theme when the current is unregistered', ->
    --   File.with_tmpfile (file) ->
    --     file.contents = serpent.dump spec_theme
    --     theme.register 'keepme', file
    --     config.theme = 'keepme'
    --     theme.unregister 'keepme'
    --     assert.equal 'keepme', theme.current.name
