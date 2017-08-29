-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:app, :Buffer, :breadcrumbs} = howl
{:File} = howl.io
{:Window} = howl.ui

describe 'breadcrumbs', ->

  buffer = (text) ->
    with Buffer {}
      .text = text

  setup ->
    app.window = Window!
    app.editor = app\new_editor!

  teardown ->
    app.editor = nil
    app.window\destroy!

  before_each ->
    app.editor.buffer = buffer ''

  after_each ->
    breadcrumbs.clear!

  describe 'drop(opts)', ->

    it 'accepts a file and a pos', ->
      file = File('/tmp/foo')
      breadcrumbs.drop :file, pos: 3
      assert.same {:file, pos: 3}, breadcrumbs.previous

    it 'accepts a file path and a pos', ->
      file = '/tmp/foo'
      breadcrumbs.drop :file, pos: 3
      assert.same {file: File(file), pos: 3}, breadcrumbs.previous

    it 'accepts a buffer and a pos', ->
      file = File('/tmp/foo')
      file.contents = '123456789\nabcdefgh'
      b = buffer ''
      b.file = file
      breadcrumbs.drop buffer: b, pos: 3
      assert.equals b.file, breadcrumbs.previous.file
      assert.equals 3, breadcrumbs.previous.pos
      assert.not_nil breadcrumbs.previous.buffer_marker

    context 'when a buffer is present', ->
      it 'sets a marker in the buffer pointing to the crumb', ->
        b = buffer '123456789\nabcdefgh'
        breadcrumbs.drop buffer: b, pos: 3
        assert.equals 3, breadcrumbs.previous.pos
        assert.not_nil breadcrumbs.previous.buffer_marker

        m = breadcrumbs.previous.buffer_marker
        marker_buffer = m.buffer_holder.buffer
        markers = marker_buffer.markers\find name: m.name
        assert.equals 1, #markers
        assert.equals 3, markers[1].start_offset
        assert.equals 3, markers[1].end_offset

    context 'when opts is missing', ->
      it 'adds a crumb for the current buffer and position', ->
        File.with_tmpfile (file) ->
          file.contents = '1234\n6789'
          app.editor.buffer.file = file
          app.editor.cursor.pos = 7
          breadcrumbs.drop!
          crumb = breadcrumbs.previous
          assert.equals 7, crumb.pos
          assert.equals app.editor.buffer, crumb.buffer_marker.buffer_holder.buffer
          assert.equals file, crumb.file

    it 'avoids adding duplicate crumbs', ->
      b = buffer '123456789'
      breadcrumbs.drop buffer: b, pos: 3
      breadcrumbs.drop buffer: b, pos: 3
      assert.equals 1, #breadcrumbs.trail
      markers = b.markers\find {}
      assert.equals 1, #markers

    context 'when forward crumbs exists', ->
      it 'invalidates all such crumbs and buffer markers', ->
        b = buffer '123456789\nabcdefgh'
        breadcrumbs.drop buffer: b, pos: 3
        breadcrumbs.drop buffer: b, pos: 6
        breadcrumbs.drop buffer: b, pos: 9
        breadcrumbs.go_back!
        breadcrumbs.go_back!
        assert.is_not_nil breadcrumbs.trail[2]
        assert.is_not_nil breadcrumbs.trail[3]
        breadcrumbs.drop buffer: b, pos: 4
        assert.equals 4, breadcrumbs.trail[2].pos
        assert.is_nil breadcrumbs.trail[3]
        markers = [m.start_offset for m in *b.markers\find({})]
        table.sort markers
        assert.same { 3, 4 }, markers

  describe 'clear', ->
    it 'invalidates any existing crumbs (buffer markers and crumbs)', ->
      b = buffer '123456789\nabcdefgh'
      breadcrumbs.drop buffer: b, pos: 3
      crumb = breadcrumbs.previous
      breadcrumbs.clear!

      assert.equals 1, breadcrumbs.location
      assert.same {}, b.markers\find name: crumb.buffer_marker.name
      assert.is_nil breadcrumbs.trail[1]

  describe 'go_back', ->
    context 'with a buffer and pos available', ->
      it 'opens the buffer and set the current position', ->
        b = buffer '123456789\nabcdefgh'
        breadcrumbs.drop buffer: b, pos: 3
        breadcrumbs.go_back!
        assert.equals 3, app.editor.cursor.pos
        assert.equals b, app.editor.buffer
        assert.equals 1, breadcrumbs.location

    context 'with a file and pos available', ->
      it 'opens the file and sets the current position', ->
        File.with_tmpfile (file) ->
          file.contents = '123456789\nabcdefgh'
          breadcrumbs.drop file: file, pos: 3
          breadcrumbs.go_back!
          assert.equals 3, app.editor.cursor.pos
          assert.equals file, app.editor.buffer.file

    context 'when the buffer has been collected', ->
      it 'falls back to the file when available', ->
        File.with_tmpfile (file) ->
          file.contents = '1234\n6789'
          b = buffer ''
          b.file = file
          breadcrumbs.drop file: file, buffer: b, pos: 3
          b = nil
          collectgarbage!
          breadcrumbs.go_back!
          assert.equals 3, app.editor.cursor.pos
          assert.equals file, app.editor.buffer.file

      it 'moves to the crumb before if present', ->
        b1 = buffer 'buffer1'
        breadcrumbs.drop buffer: b1, pos: 3

        b2 = buffer 'buffer2'
        breadcrumbs.drop buffer: b2, pos: 5

        b2 = nil
        collectgarbage!

        breadcrumbs.go_back!
        assert.equals 3, app.editor.cursor.pos
        assert.equals b1, app.editor.buffer
        assert.equals 1, breadcrumbs.location

    it 'inserts a crumb if needed before going back', ->
        b = buffer '123456789'
        app.editor.buffer = b
        app.editor.cursor.pos = 2
        breadcrumbs.drop buffer: b, pos: 3
        breadcrumbs.drop buffer: b, pos: 5
        app.editor.cursor.pos = 7
        breadcrumbs.go_back!
        assert.equals 5, app.editor.cursor.pos -- at pos 5
        assert.equals 2, breadcrumbs.location -- at breadcrumbs location 2
        assert.equals 3, #breadcrumbs.trail -- with two forward crumbs
        assert.equals 5, breadcrumbs.trail[2].pos -- the old one
        assert.equals 7, breadcrumbs.trail[3].pos -- and the newly inserted

        breadcrumbs.go_back!
        assert.equals 3, app.editor.cursor.pos -- at pos 3
        assert.equals 1, breadcrumbs.location -- at breadcrumbs location 1
        -- we shouldn't have any added crumb added for this case
        assert.equals 3, #breadcrumbs.trail -- only three forward crumbs
        assert.same {3, 5, 7}, [c.pos for c in *breadcrumbs.trail]

  describe 'go_forward', ->
    context 'with a buffer and pos available', ->
      it 'opens the buffer and set the current position', ->
        b = buffer '123456789\nabcdefgh'
        breadcrumbs.drop buffer: b, pos: 3
        breadcrumbs.drop buffer: b, pos: 7
        breadcrumbs.go_back!
        breadcrumbs.go_back!
        breadcrumbs.go_forward!
        assert.equals 7, app.editor.cursor.pos
        assert.equals b, app.editor.buffer

    context 'with a file and pos available', ->
      it 'opens the file and sets the current position', ->
        File.with_tmpfile (file) ->
          file.contents = '123456789\nabcdefgh'
          breadcrumbs.drop file: file, pos: 3
          breadcrumbs.drop file: file, pos: 7
          breadcrumbs.go_back!
          breadcrumbs.go_back!
          breadcrumbs.go_forward!
          assert.equals 7, app.editor.cursor.pos
          assert.equals file, app.editor.buffer.file

    context 'when the buffer has been collected', ->
      it 'falls back to the file when available', ->
        File.with_tmpfile (file) ->
          file.contents = '1234\n6789'
          b = buffer ''
          b.file = file
          breadcrumbs.drop file: file, buffer: b, pos: 3
          breadcrumbs.drop file: file, buffer: b, pos: 7
          b = nil
          breadcrumbs.go_back!
          breadcrumbs.go_back!
          collectgarbage!
          breadcrumbs.go_forward!
          assert.equals 7, app.editor.cursor.pos
          assert.equals file, app.editor.buffer.file

      it 'moves to the crumb after if present', ->
        b1 = buffer 'buffer1'
        breadcrumbs.drop buffer: b1, pos: 3
        breadcrumbs.drop buffer: b1, pos: 4

        b2 = buffer 'buffer2'
        breadcrumbs.drop buffer: b2, pos: 5

        breadcrumbs.go_back!
        breadcrumbs.go_back!

        b1 = nil
        collectgarbage!
        breadcrumbs.go_forward!

        assert.equals 5, app.editor.cursor.pos
        assert.equals b2, app.editor.buffer

    it 'inserts a crumb if needed before going forward', ->
        b = buffer '123456789'
        app.editor.buffer = b
        breadcrumbs.drop buffer: b, pos: 3
        breadcrumbs.drop buffer: b, pos: 5
        breadcrumbs.drop buffer: b, pos: 7
        app.editor.cursor.pos = 7
        breadcrumbs.go_back!
        breadcrumbs.go_back!
        breadcrumbs.go_back!

        -- we start out with the three crumbs above, at pos 3
        assert.equals 3, app.editor.cursor.pos
        assert.equals 3, #breadcrumbs.trail -- with three forward crumbs
        assert.equals 1, breadcrumbs.location -- at breadcrumbs location 1

        -- -- we'll move the cursor some and then go forward
        app.editor.cursor.pos = 4
        breadcrumbs.go_forward!
        assert.equals 5, app.editor.cursor.pos -- at pos 5

        -- -- this should have inserted a new crumb at the interim location
        assert.equals 4, #breadcrumbs.trail -- with two forward crumbs
        assert.equals 3, breadcrumbs.location -- with location thus = 3
        assert.equals 3, breadcrumbs.trail[1].pos -- old back crumb
        assert.equals 4, breadcrumbs.trail[2].pos -- newly inserted
        assert.equals 5, breadcrumbs.trail[3].pos -- old forward crumb
        assert.equals 7, breadcrumbs.trail[4].pos -- old forward crumb

        -- -- forward again, without interim movement
        breadcrumbs.go_forward!
        assert.equals 7, app.editor.cursor.pos -- at pos 5

        -- -- this should not have introduced any new crumb
        assert.equals 4, #breadcrumbs.trail
        assert.equals 4, breadcrumbs.location

  it 'memory management', ->
    it 'keeps weak references to buffers', ->
      holder = setmetatable {
        buffer: buffer '123456789\nabcdefgh'
      }, __mode: 'v'

      breadcrumbs.drop buffer: holder.buffer, pos: 3
      collectgarbage!
      assert.is_nil holder.buffer
