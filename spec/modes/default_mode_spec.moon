import DefaultMode from howl.modes
import Buffer from howl
import Editor from howl.ui

describe 'DefaultMode', ->
  local buffer, mode, lines
  editor = Editor Buffer {}
  cursor = editor.cursor
  selection = editor.selection
   -- window = Gtk.OffscreenWindow!
  -- window\add editor\to_gobject!
  -- window\show_all!

  -- teardown ->
  --   window\destroy!

  before_each ->
    buffer = Buffer {}
    mode = DefaultMode!
    buffer.mode = mode
    buffer.config.indent = 2
    lines = buffer.lines
    editor.buffer = buffer

  describe 'comment(editor)', ->
    text = [[
  liñe 1

    liñe 2
    liñe 3
  ]]
    before_each ->
      buffer.text = text
      selection\set 1, lines[4].start_pos

    context 'when .short_comment_prefix is not set', ->
      it 'does nothing', ->
        mode\comment editor
        assert.equal text, buffer.text

    context 'when .short_comment_prefix is set', ->
      before_each -> mode.short_comment_prefix = '--'

      it 'prefixes the selected lines with the prefix and a space, at the minimum indentation level', ->
        mode\comment editor
        assert.equal [[
  -- liñe 1

  --   liñe 2
    liñe 3
  ]], buffer.text

      it 'comments the current line if nothing is selected', ->
        selection\remove!
        cursor.pos = 1
        mode\comment editor
        assert.equal [[
  -- liñe 1

    liñe 2
    liñe 3
  ]], buffer.text

      it 'keeps the cursor position', ->
        editor.selection.cursor = lines[3].start_pos + 2
        mode\comment editor
        assert.equal 6, cursor.column

  describe 'uncomment(editor)', ->
    text = [[
  --  liñe 1
    -- -- liñe 2
    --liñe 3
]]
    before_each ->
      buffer.text = text
      selection\set 1, lines[3].start_pos

    context 'when .short_comment_prefix is not set', ->
      it 'does nothing', ->
        mode\uncomment editor
        assert.equal text, buffer.text

    context 'when .short_comment_prefix is set', ->
      before_each -> buffer.mode.short_comment_prefix = '--'

      it 'removes the first instance of the comment prefix and optional space from each line', ->
        mode\uncomment editor
        assert.equal [[
   liñe 1
    -- liñe 2
    --liñe 3
]], buffer.text

      it 'uncomments the current line if nothing is selected', ->
        selection\remove!
        cursor.line = 2
        mode\uncomment editor
        assert.equal [[
  --  liñe 1
    -- liñe 2
    --liñe 3
]], buffer.text

      it 'keeps the cursor position', ->
        editor.selection.cursor = lines[2].start_pos + 6
        mode\uncomment editor
        assert.equal 4, cursor.column

      it 'does nothing for lines that are not commented', ->
        buffer.text = "line\n"
        cursor.line = 1
        mode\uncomment editor
        assert.equal "line\n", buffer.text

  describe 'toggle_comment(editor)', ->
    context 'when mode does not provide .short_comment_prefix', ->
      it 'does nothing', ->
        buffer.text = '-- foo'
        mode\toggle_comment editor
        assert.equal '-- foo', buffer.text

    context 'when mode provides .short_comment_prefix', ->
      before_each -> buffer.mode.short_comment_prefix = '--'

      it 'it uncomments if the first line starts with the comment prefix', ->
        buffer.text = '  -- foo'
        mode\toggle_comment editor
        assert.equal '  foo', buffer.text

      it 'comments if the first line do no start with the comment prefix', ->
        buffer.text = 'foo'
        mode\toggle_comment editor
        assert.equal '-- foo', buffer.text
