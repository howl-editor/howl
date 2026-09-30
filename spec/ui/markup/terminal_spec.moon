m = howl.ui.markup.terminal
{:config} = howl
{:StyledText, :style, :theme} = howl.ui
{:File} = howl.io

describe 'terminal', ->

  it 'returns a StyledText instance with empty styles if no markup is detected', ->
    assert.same StyledText('foo', {}), m 'foo'

  context 'ANSI escape sequences', ->

    it 'handles bold', ->
      expected = StyledText 'foo', { 1, 'ansi_bold', 4 }
      assert.same expected, m '\027[1mfoo\027[0m'

    it 'handles italic', ->
      expected = StyledText 'foo', { 1, 'ansi_italic', 4 }
      assert.same expected, m '\027[3mfoo\027[0m'

    it 'handles underline', ->
      expected = StyledText 'foo', { 1, 'ansi_underline', 4 }
      assert.same expected, m '\027[4mfoo\027[0m'

    it 'handles background colors', ->
      expected = StyledText 'foo', { 1, 'ansi_red', 4 }
      assert.same expected, m '\027[31mfoo\027[0m'

    it 'handles background colors', ->
      expected = StyledText 'foo', { 1, 'ansi_on_red', 4 }
      assert.same expected, m '\027[41mfoo\027[0m'

    it 'handles combined foreground and background colors', ->
      expected = StyledText 'foo', { 1, 'ansi_green_on_red', 4 }
      assert.same expected, m '\027[41;32mfoo\027[0m'

    it 'styles remain in effect until resetted', ->
      expected = StyledText 'foobar', {
        1, 'ansi_on_red', 4
        4, 'ansi_green_on_red', 7
      }
      assert.same expected, m '\027[41mfoo\027[32mbar\027[0m'

    it 'handles empty reset sequences', ->
      expected = StyledText 'foobar', { 1, 'ansi_italic', 4 }
      assert.same expected, m '\027[3mfoo\027[mbar'

    it 'handles prematurely terminated sequences', ->
      expected = StyledText 'foo', { 1, 'ansi_red', 4 }
      assert.same expected, m '\027[31mfoo'

    it 'handles foreground color resetting', ->
      expected = StyledText 'foobar', { 1, 'ansi_red', 4 }
      assert.same expected, m '\027[31mfoo\027[39mbar'

    it 'handles background color resetting', ->
      expected = StyledText 'foobar', { 1, 'ansi_on_red', 4 }
      assert.same expected, m '\027[41mfoo\027[49mbar'

    it 'skips over unhandled escape sequences', ->
      expected = StyledText 'foo', {}
      assert.same expected, m '\027[2,2Hfoo'

    it 'ignores unhandled graphic parameters', ->
      expected = StyledText 'foo', { 1, 'ansi_red', 4 }
      assert.same expected, m '\027[31;5;6mfoo\027[m'

    it 'takes the colors of the current theme, also after switching themes', ->
      File.with_tmpfile (first) ->
        File.with_tmpfile (second) ->
          first.contents = 'style.magenta { color: #110000; } style.cyan { color: #001100; }'
          second.contents = 'style.magenta { color: #220000; } style.cyan { color: #002200; }'
          theme.register 'ansi-first', first
          theme.register 'ansi-second', second
          config.theme = 'ansi-first'
          m '\027[35;46mfoo'
          assert.equals '#110000', style.ansi_magenta_on_cyan.color

          config.theme = 'ansi-second'
          assert.equals '#220000', style.ansi_magenta_on_cyan.color
          assert.equals '#002200', style.ansi_magenta_on_cyan.background

  context 'backspace characters (BS)', ->
    it 'deletes back properly', ->
      expected = StyledText 'fo', {}
      assert.same expected, m 'foo\008'

    it 'deletes a UTF-8 code point back, and not a byte', ->
      expected = StyledText 'åä', {}
      assert.same expected, m 'åäö\008'

    it 'BS at the start of the text is left alone', ->
      expected = StyledText '\008foo', {}
      assert.same expected, m '\008foo'

    it 'updates the styling accordingly', ->
      expected = StyledText 'fobar', { 1, 'ansi_red', 3 }
      assert.same expected, m '\027[31mfoo\027[m\008bar'

    it 'removes any left empty styling', ->
      expected = StyledText 'fobar', { }
      assert.same expected, m 'fo\027[31mo\027[m\008bar'
