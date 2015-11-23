import File from howl.io
import Application, Buffer, mode from howl
import Editor from howl.ui

describe 'Application', ->
  local root_dir, application

  before_each ->
    root_dir = File.tmpdir!
    application = Application root_dir, {}

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

  describe 'open_file(file, editor)', ->
    editor = Editor Buffer {}

    it 'opens the file in the specified editor if given', ->
      File.with_tmpfile (file) ->
        file.contents = 'well hello there'
        application\open_file file, editor
        assert.equal file.contents, editor.buffer.text

    it 'returns the newly created buffer', ->
      File.with_tmpfile (file) ->
        buffer = application\open_file file, editor
        assert.equal buffer, editor.buffer

    it 'adds the buffer to @buffers', ->
      File.with_tmpfile (file) ->
        buffer = application\open_file file, editor
        assert.same { buffer }, application.buffers

    context 'when <file> is already open', ->
      it 'switches to editor to the existing buffer instead of creating a new one', ->
        with_tmpdir (dir) ->
          a = dir / 'a.foo'
          b = dir / 'b.foo'
          buffer = application\open_file a, editor
          application\open_file b, editor
          application\open_file a, editor
          assert.equal 2, #application.buffers
          assert.equal buffer, editor.buffer

    it 'fires the file-opened signal', ->
      with_signal_handler 'file-opened', nil, (handler) ->
        File.with_tmpfile (file) ->
          application\open_file file, editor
        assert.spy(handler).was_called!

  it '.buffers are sorted by visibility status and last_shown', ->
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

    buffers = [b.title for b in *application.buffers]
    assert.same { 'visible', 'last_shown', 'hidden' }, buffers

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
