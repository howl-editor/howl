Display = require 'ljglibs.gdk.display'
-- Clipboard = require 'ljglibs.gdk.clipboard'
clipboard = Display.get_default!.clipboard
primary_clipboard = Display.get_default!.primary_clipboard

describe 'Clipboard', ->
  setup -> set_howl_loop!

  describe 'manipulation and access', ->
    it 'allows setting and retrieving content', (done) ->
      clipboard\set_text 'hello!'
      clipboard\read_text_async async (res) ->
        assert.equals 'hello!', clipboard\read_text_finish(res)
        done!

    it 'allows setting and retrieving text for primary', (done) ->
      primary_clipboard\set_text 'primary'
      primary_clipboard\read_text_async async (res) ->
        assert.equals 'primary', primary_clipboard\read_text_finish(res)
        done!
