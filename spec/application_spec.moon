import File from lunar.fs
import Application, Buffer, mode from lunar
import Editor from lunar.ui

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
      with_tmpfile (file) ->
        file.contents = 'well hello there'
        application\open_file file, editor
        assert.equal file.contents, editor.buffer.text

    it 'returns the newly created buffer', ->
      with_tmpfile (file) ->
        buffer = application\open_file file, editor
        assert.equal buffer, editor.buffer

    it 'adds the buffer to @buffers', ->
      with_tmpfile (file) ->
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

  it '.buffers are sorted by visibility status and last_shown', ->
    sci = {}
    hidden_buffer = application\new_buffer!
    hidden_buffer.title = 'hidden'

    last_shown_buffer = application\new_buffer!
    last_shown_buffer\add_sci_ref sci
    last_shown_buffer\remove_sci_ref sci
    last_shown_buffer.title = 'last_shown'

    visible_buffer = application\new_buffer!
    visible_buffer\add_sci_ref sci
    visible_buffer.title = 'visible'

    buffers = [b.title for b in *application.buffers]
    assert.same { 'visible', 'last_shown', 'hidden' }, buffers