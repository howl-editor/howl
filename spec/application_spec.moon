{:File} = howl.io
{:Application, :Buffer, :config, :mode} = howl
{:Editor, :highlight} = howl.ui

describe 'Application', ->
  local root_dir, application

  before_each ->
    root_dir = File.tmpdir!
    application = Application root_dir, {}
    config.autoclose_single_buffer = false

  after_each -> root_dir\delete_all!

  describe 'new_buffer(mode)', ->
    it 'creates a new buffer with mode', ->
      m = mode.by_name 'default'
      buffer = application\new_buffer m
      assert.equal m, buffer.mode

    it 'uses the default mode if no mode is specifed', ->
      buffer = application\new_buffer!
      assert.equal 'default', buffer.mode.name

    it 'registers the new buffer in .buffers', ->
      buffer = application\new_buffer!
      assert.same { buffer }, application.buffers

    it 'closes a single untitled buffer if present', ->
      config.autoclose_single_buffer = true
      application\new_buffer!
      buffer = application\new_buffer!
      assert.same { buffer }, application.buffers

  describe 'add_buffer(buffer, show)', ->
    it 'adds the buffer to .buffers', ->
      buf = Buffer {}
      application\add_buffer buf
      assert.same {buf}, application.buffers

    it 'shows the buffer in the current editor', ->
      buf = Buffer {}
      application.editor = Editor Buffer {}
      application\add_buffer buf
      assert.equals buf, application.editor.buffer

    it 'does not shows the buffer in the current editor if <show> is false', ->
      buf = Buffer {}
      application.editor = Editor Buffer {}
      application\add_buffer buf, false
      assert.not_equals buf, application.editor.buffer

    it 'prevents the same buffer from being added twice', ->
      buf = Buffer {}
      application\add_buffer buf
      application\add_buffer buf
      assert.equals 1, #application.buffers

  describe 'open(location, editor)', ->
    local editor
    before_each ->
      editor = Editor Buffer {}

    context 'when location.file is given', ->

      it 'opens the file in the specified editor if given', ->
        File.with_tmpfile (file) ->
          file.contents = 'well hello there'
          application\open :file, editor
          assert.equal file.contents, editor.buffer.text

      it 'returns the newly created buffer', ->
        File.with_tmpfile (file) ->
          buffer = application\open :file, editor
          assert.equal buffer, editor.buffer

      it 'adds the buffer to @buffers', ->
        File.with_tmpfile (file) ->
          buffer = application\open :file, editor
          assert.same { buffer }, application.buffers

      context 'when <file> is already open', ->
        it 'switches to editor to the existing buffer instead of creating a new one', ->
          with_tmpdir (dir) ->
            a = dir / 'a.foo'
            b = dir / 'b.foo'
            buffer = application\open file: a, editor
            application\open file: b, editor
            application\open file: a, editor
            assert.equal 2, #application.buffers
            assert.equal buffer, editor.buffer

      it 'fires the file-opened signal', ->
        with_signal_handler 'file-opened', nil, (handler) ->
          File.with_tmpfile (file) ->
            application\open :file, editor
          assert.spy(handler).was_called!

    context 'when location.buffer is given', ->

      it 'opens the file in the specified editor if given', ->
        buffer = Buffer {}
        buffer.text = 'my-buf'
        application\open :buffer, editor
        assert.equal 'my-buf', editor.buffer.text

      it 'returns the buffer', ->
        buffer = Buffer {}
        buf2 = application\open :buffer, editor
        assert.equal buffer, buf2

      it 'adds the buffer to @buffers', ->
        buffer = Buffer {}
        application\open :buffer, editor
        assert.same { buffer }, application.buffers

    it '.line_nr specifies a line nr to go to', ->
      buffer = Buffer {}
      buffer.text = 'one\ntwo\nthree'
      application\open {:buffer, line_nr: 2}, editor
      assert.equal 2, editor.cursor.line

    it '.column specifies a column to go to', ->
      buffer = Buffer {}
      buffer.text = 'one'
      application\open {:buffer, line_nr: 1, column: 2}, editor
      assert.equal 2, editor.cursor.column

    it '.column_index specifies an offsetted column to go to', ->
      buffer = Buffer {}
      buffer.text = '1\tX'
      application\open {:buffer, line_nr: 1, column_index: 3}, editor
      assert.equal 3, editor.cursor.column_index
      assert.not_equal 3, editor.cursor.column

    it 'highlight any highlights', ->
      buffer = Buffer {}
      buffer.text = '123456789'
      application\open {
        :buffer, line_nr: 1, column: 3,
        highlights: {
          { start_pos: 2, end_pos: 3 },
          { start_column: 5, end_column: 7, highlight: 'foo' }
        }
      }, editor
      assert.same { 'search' }, highlight.at_pos(buffer, 2)
      assert.same {}, highlight.at_pos(buffer, 3)
      assert.same { 'foo' }, highlight.at_pos(buffer, 5)
      assert.same { 'foo' }, highlight.at_pos(buffer, 6)

  it '.buffers are sorted by focus, visibility status and last_shown', ->
    view = {}
    hidden_buffer = application\new_buffer!
    hidden_buffer.title = 'hidden'

    last_shown_buffer = application\new_buffer!
    last_shown_buffer\add_view_ref view
    last_shown_buffer\remove_view_ref view
    last_shown_buffer.title = 'last_shown'
    editor = Editor last_shown_buffer

    visible_buffer = application\new_buffer!
    editor.buffer = visible_buffer
    visible_buffer.title = 'visible'

    visible_focus_buffer = application\new_buffer!
    visible_focus_buffer.title = 'visible-focus'
    application.editor = buffer: visible_focus_buffer

    buffers = [b.title for b in *application.buffers]
    assert.same { 'visible-focus', 'visible', 'last_shown', 'hidden' }, buffers

  describe '.recently_closed', ->
    editor = Editor Buffer {}

    it 'contains recently closed files', ->
      File.with_tmpfile (file) ->
        file.contents = 'test'
        buffer = application\open_file(file, editor)
        application\close_buffer(buffer)
        assert.same {file.path}, [f.file.path for f in *application.recently_closed]

    it 'does not show open files', ->
      File.with_tmpfile (file) ->
        file.contents = 'test'
        buffer = application\open_file(file, editor)
        application\close_buffer(buffer)
        application\open_file(file, editor)
        assert.same {}, [f.file.path for f in *application.recently_closed]

    it 'limits number of saved files to config.recently_closed_limit', ->
      howl.config.recently_closed_limit = 1
      File.with_tmpfile (file1) -> File.with_tmpfile (file2) ->
        file1.contents = 'test'
        file2.contents = 'test'
        buffer1 = application\open_file(file1, editor)
        buffer2 = application\open_file(file2, editor)
        application\close_buffer buffer1
        application\close_buffer buffer2
        assert.same {file2.path}, [f.file.path for f in *application.recently_closed]

  describe 'synchronize()', ->
    context "when a buffer's file has changed on disk", ->
      local b

      before_each ->
        reload = spy.new -> nil
        b = application\new_buffer!
        b.reload = reload
        rawset b, 'modified_on_disk', true

      it 'the buffer is reloaded automatically if it is not modified', ->
        application\synchronize!
        assert.spy(b.reload).was_called!

      it 'the buffer is not reloaded automatically if it is modified', ->
        b.modified = true
        application\synchronize!
        assert.spy(b.reload).was_not_called!
