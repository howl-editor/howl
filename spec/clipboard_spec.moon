Display = require 'ljglibs.gdk.display'

display = Display.get_default!
system_cb = display.clipboard
primary_cb = display.primary_clipboard

{:clipboard, :config} = howl

describe 'Clipboard', ->
  setup -> set_howl_loop!

  before_each ->  clipboard.clear!

  describe 'push(item, opts = {})', ->
    context 'when <item> is a string', ->
      it 'adds a clip item containing text to the clipboard', ->
        clipboard.push 'hello!'
        assert.equals 'hello!', clipboard.current.text

    context 'when <item> is a table', ->
      it 'adds the clip item as is to the clipboard', ->
        clipboard.push text: 'hello!'
        assert.equals 'hello!', clipboard.current.text

      it 'raises an error if <item> has no .text field', ->
        assert.raises 'text', -> clipboard.push {}

    context 'when opts contains a ".to" field', ->
      it 'pushes the item to the specified target', ->
        clipboard.push 'hello!', to: 'a'
        assert.is_nil clipboard.current
        assert.equals 'hello!', clipboard.registers.a.text

    context 'when no ".to" field is specified in opts', ->
      it 'ensures the number of clips does not exceed config.clipboard_max_items', ->
        config.clipboard_max_items = 5
        for i = 1,6
          clipboard.push "clip #{i}"

        assert.equals 5, #clipboard.clips
        assert.equals 'clip 6', clipboard.clips[1].text
        assert.equals 'clip 2', clipboard.clips[5].text

      it 'copies the clip to the system clipboard as well', (done) ->
        clipboard.push 'global!'
        system_cb\read_text_async async (res) ->
          assert.equals 'global!', system_cb\read_text_finish(res)
          done!

  describe 'clear()', ->
    it 'clears all clips', ->
      clipboard.push 'hello!'
      clipboard.push 'to register!', to: 'a'
      clipboard.clear!
      assert.is_nil clipboard.current
      assert.is_nil clipboard.registers.a

  describe 'synchronize()', ->
    it 'adds the clip from the system clipboard if it differs from .current', (done) ->
      system_cb\set_text 'pushed'
      clipboard.synchronize async ->
        assert.equals 'pushed', clipboard.current.text
        done!

    it 'does nothing if the texts are the same', (done) ->
      clipboard.push 'pushed'
      system_cb\set_text 'pushed'
      clipboard.synchronize async ->
        assert.equals 'pushed', clipboard.current.text
        assert.equals 1, #clipboard.clips
        done!

  describe '.primary', ->

    it 'allows getting and setting the primary clipboard', (done) ->
      clipboard.primary.text = 'spec'
      primary_cb\read_text_async async (res) ->
        assert.equals 'spec', primary_cb\read_text_finish res
        done!
