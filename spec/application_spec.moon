import File from lunar.fs
import Application, mode from lunar

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