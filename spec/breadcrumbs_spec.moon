-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:app, :Buffer, :breadcrumbs, :config} = howl
{:File} = howl.io
{:Window} = howl.ui

describe 'breadcrumbs', ->
  local editor, cursor, old_tolerance

  buffer = (text) ->
    with Buffer {}
      .text = text

  setup ->
    app.window = Window!
    editor = app\new_editor!
    cursor = editor.cursor
    app.editor = editor
    breadcrumbs.init!
    old_tolerance = config.breadcrumb_tolerance

  teardown ->
    config.breadcrumb_tolerance = old_tolerance
    app.editor = nil
    app.window\destroy!

  before_each ->
    app.editor.buffer = buffer ''
    config.breadcrumb_tolerance = 0

  after_each ->
    breadcrumbs.clear!

  describe 'drop(opts)', ->

    it 'accepts a file and a pos', ->
      File.with_tmpfile (file) ->
        breadcrumbs.drop :file, pos: 3
        assert.same {:file, pos: 3}, breadcrumbs.previous

    it 'accepts a file path and a pos', ->
      File.with_tmpfile (file) ->
        breadcrumbs.drop :file, pos: 3
        assert.same {file: File(file), pos: 3}, breadcrumbs.previous

    it 'accepts a buffer and a pos', ->
      File.with_tmpfile (file) ->
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
        marker_buffer = m.buffer
        markers = marker_buffer.markers\find name: m.name
        assert.equals 1, #markers
        assert.equals 3, markers[1].start_offset
        assert.equals 3, markers[1].end_offset

    context 'when opts is missing', ->
      it 'adds a crumb for the current buffer and position', ->
        File.with_tmpfile (file) ->
          file.contents = '1234\n6789'
          editor.buffer.file = file
          cursor.pos = 7
          breadcrumbs.drop!
          crumb = breadcrumbs.previous
          assert.equals 7, crumb.pos
          assert.equals editor.buffer, crumb.buffer_marker.buffer
          assert.equals file, crumb.file

    context 'when forward crumbs exists', ->
      it 'invalidates all such crumbs and buffer markers', ->
        b = buffer '123456789\nabcdefgh'
        editor.buffer = b
        breadcrumbs.drop buffer: b, pos: 3
        breadcrumbs.drop buffer: b, pos: 6
        breadcrumbs.drop buffer: b, pos: 9
        cursor.pos = 10
        breadcrumbs.go_back! -- loc 3
        assert.equals 4, #breadcrumbs.trail
        breadcrumbs.go_back! -- loc 2
        assert.equals 4, #breadcrumbs.trail
        assert.is_not_nil breadcrumbs.trail[2]
        assert.is_not_nil breadcrumbs.trail[3]
        assert.is_not_nil breadcrumbs.trail[4]

        assert.equals 2, breadcrumbs.location
        breadcrumbs.drop buffer: b, pos: 4
        assert.equals 4, breadcrumbs.trail[2].pos
        assert.is_nil breadcrumbs.trail[3]

        markers = [m.start_offset for m in *b.markers\find({})]
        table.sort markers
        assert.same { 3, 4 }, markers

    context '(tolerance handling)',
      it 'merges crumbs when their distance is within the tolerance', ->
        buf = editor.buffer
        buf.text = string.rep('123456789\n', 10)
        config.breadcrumb_tolerance = 5

        breadcrumbs.drop buffer: buf, pos: 1
        breadcrumbs.drop buffer: buf, pos: 6
        assert.equals 1, #breadcrumbs.trail
        assert.equals 6, breadcrumbs.trail[1].pos
        markers = [m.start_offset for m in *buf.markers\find({})]
        assert.same { 6 }, markers
        breadcrumbs.drop buffer: buf, pos: 12
        assert.equals 2, #breadcrumbs.trail
        assert.equals 12, breadcrumbs.trail[2].pos
        markers = [m.start_offset for m in *buf.markers\find({})]
        assert.same { 6, 12 }, markers

    context 'house cleaning according to breadcrumb_limit', ->
      local old_limit

      before_each ->
        old_limit = config.breadcrumb_limit
        config.breadcrumb_limit = 2

      after_each ->
        config.breadcrumb_limit = old_limit

      it 'purges old crumbs according to breadcrumb_limit', ->
        b = buffer '123456789\nabcdefgh'
        breadcrumbs.drop buffer: b, pos: 1
        breadcrumbs.drop buffer: b, pos: 2
        breadcrumbs.drop buffer: b, pos: 3

        assert.equals 2, #breadcrumbs.trail
        assert.equals 3, breadcrumbs.location
        assert.same {2, 3}, [c.pos for c in *breadcrumbs.trail]

  describe 'crumb cleaning', ->
    it 'removes duplicate crumbs', ->
      b = buffer '123456789'
      breadcrumbs.drop buffer: b, pos: 3
      breadcrumbs.drop buffer: b, pos: 3
      assert.equals 1, #breadcrumbs.trail
      markers = b.markers\find {}
      assert.equals 1, #markers

    it 'reduces unnecessary loops', ->
      b = buffer '123456789'
      breadcrumbs.drop buffer: b, pos: 3
      breadcrumbs.drop buffer: b, pos: 6
      breadcrumbs.drop buffer: b, pos: 3
      breadcrumbs.drop buffer: b, pos: 6
      assert.equals 2, #breadcrumbs.trail
      assert.equals 3, breadcrumbs.location

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
        assert.equals 3, cursor.pos
        assert.equals b, editor.buffer
        assert.equals 1, breadcrumbs.location

      it 'uses a buffer marker for positioning to account for updates', ->
        b = buffer '123456789'
        breadcrumbs.drop buffer: b, pos: 6
        b\insert 'xx', 2
        breadcrumbs.go_back!
        assert.equals 8, cursor.pos

    context 'with a file and pos available', ->
      it 'opens the file and sets the current position', ->
        File.with_tmpfile (file) ->
          file.contents = '123456789\nabcdefgh'
          breadcrumbs.drop file: file, pos: 3
          breadcrumbs.go_back!
          assert.equals 3, cursor.pos
          assert.equals file, editor.buffer.file

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
          assert.equals 3, cursor.pos
          assert.equals file, editor.buffer.file

      it 'moves to the crumb before if present', ->
        b1 = buffer 'buffer1'
        breadcrumbs.drop buffer: b1, pos: 3

        b2 = buffer 'buffer2'
        breadcrumbs.drop buffer: b2, pos: 5

        b2 = nil
        collectgarbage!

        breadcrumbs.go_back!
        assert.equals 3, cursor.pos
        assert.equals b1, editor.buffer
        assert.equals 1, breadcrumbs.location

    it 'inserts a crumb if needed before going back', ->
        b = buffer '123456789'
        editor.buffer = b
        cursor.pos = 2
        breadcrumbs.drop buffer: b, pos: 3
        breadcrumbs.drop buffer: b, pos: 5
        cursor.pos = 7
        breadcrumbs.go_back!
        assert.equals 5, cursor.pos -- at pos 5
        assert.equals 2, breadcrumbs.location -- at breadcrumbs location 2
        assert.equals 3, #breadcrumbs.trail -- with two forward crumbs
        assert.equals 5, breadcrumbs.trail[2].pos -- the old one
        assert.equals 7, breadcrumbs.trail[3].pos -- and the newly inserted

        breadcrumbs.go_back!
        assert.equals 3, cursor.pos -- at pos 3
        assert.equals 1, breadcrumbs.location -- at breadcrumbs location 1
        -- we shouldn't have any added crumb added for this case
        assert.equals 3, #breadcrumbs.trail -- only three forward crumbs
        assert.same {3, 5, 7}, [c.pos for c in *breadcrumbs.trail]

    context '(tolerance handling)', ->
      it 'moves beyond the previous crumb if it is within the distance', ->
        b = editor.buffer
        b.text = string.rep('1234567890', 2)
        config.breadcrumb_tolerance = 2
        breadcrumbs.drop buffer: b, pos: 1
        breadcrumbs.drop buffer: b, pos: 4
        breadcrumbs.drop buffer: b, pos: 7
        breadcrumbs.drop buffer: b, pos: 10
        cursor.pos = 12
        breadcrumbs.go_back!
        assert.equals 7, cursor.pos
        breadcrumbs.go_back!
        assert.equals 4, cursor.pos

  describe 'go_forward', ->
    context 'with a buffer and pos available', ->
      it 'opens the buffer and set the current position', ->
        b = buffer '123456789\nabcdefgh'
        breadcrumbs.drop buffer: b, pos: 3
        breadcrumbs.drop buffer: b, pos: 7
        breadcrumbs.go_back!
        breadcrumbs.go_back!
        breadcrumbs.go_forward!
        assert.equals 7, cursor.pos
        assert.equals b, editor.buffer

      it 'uses a buffer marker for positioning to account for updates', ->
        b = buffer '123456789'
        breadcrumbs.drop buffer: b, pos: 1
        breadcrumbs.drop buffer: b, pos: 6
        breadcrumbs.go_back!
        breadcrumbs.go_back!
        b\insert 'xx', 2
        breadcrumbs.go_forward!
        assert.equals 8, cursor.pos

    context 'with a file and pos available', ->
      it 'opens the file and sets the current position', ->
        File.with_tmpfile (file) ->
          file.contents = '123456789\nabcdefgh'
          breadcrumbs.drop file: file, pos: 3
          breadcrumbs.drop file: file, pos: 7
          breadcrumbs.go_back!
          breadcrumbs.go_back!
          breadcrumbs.go_forward!
          assert.equals 7, cursor.pos
          assert.equals file, editor.buffer.file

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
          assert.equals 7, cursor.pos
          assert.equals file, editor.buffer.file

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

        assert.equals 5, cursor.pos
        assert.equals b2, editor.buffer

    it 'inserts a crumb if needed before going forward', ->
        b = buffer '123456789'
        editor.buffer = b
        breadcrumbs.drop buffer: b, pos: 3
        breadcrumbs.drop buffer: b, pos: 5
        breadcrumbs.drop buffer: b, pos: 7
        cursor.pos = 7
        breadcrumbs.go_back!
        breadcrumbs.go_back!
        breadcrumbs.go_back!

        -- we start out with the three crumbs above, at pos 3
        assert.equals 3, cursor.pos
        assert.equals 3, #breadcrumbs.trail -- with three forward crumbs
        assert.equals 1, breadcrumbs.location -- at breadcrumbs location 1

        -- -- we'll move the cursor some and then go forward
        cursor.pos = 4
        breadcrumbs.go_forward!
        assert.equals 5, cursor.pos -- at pos 5

        -- -- this should have inserted a new crumb at the interim location
        assert.equals 4, #breadcrumbs.trail -- with two forward crumbs
        assert.equals 3, breadcrumbs.location -- with location thus = 3
        assert.equals 3, breadcrumbs.trail[1].pos -- old back crumb
        assert.equals 4, breadcrumbs.trail[2].pos -- newly inserted
        assert.equals 5, breadcrumbs.trail[3].pos -- old forward crumb
        assert.equals 7, breadcrumbs.trail[4].pos -- old forward crumb

        -- -- -- forward again, without interim movement
        breadcrumbs.go_forward!
        assert.equals 7, cursor.pos -- at pos 5

        -- -- -- this should not have introduced any new crumb
        assert.equals 4, #breadcrumbs.trail
        assert.equals 4, breadcrumbs.location

    context '(tolerance handling)', ->
      it 'moves beyond the next crumb if it is within the distance', ->
        b = editor.buffer
        b.text = string.rep('1234567890', 2)
        config.breadcrumb_tolerance = 2
        breadcrumbs.drop buffer: b, pos: 1
        breadcrumbs.drop buffer: b, pos: 4
        breadcrumbs.drop buffer: b, pos: 7
        breadcrumbs.go_back!
        breadcrumbs.go_back!
        breadcrumbs.go_back!

        cursor.pos = 2
        breadcrumbs.go_forward!
        assert.equals 7, cursor.pos

  context 'when a buffer is closed', ->
    it 'removes any crumbs missing a file reference', ->
      b1 = buffer '123456789'
      b2 = app\new_buffer!
      b2.text = '123456789'
      b2.modified = false
      breadcrumbs.drop buffer: b1, pos: 3
      breadcrumbs.drop buffer: b2, pos: 5
      breadcrumbs.drop buffer: b1, pos: 7
      assert.equals 3, #breadcrumbs.trail
      assert.equals 4, breadcrumbs.location
      app\close_buffer b2
      assert.equals 2, #breadcrumbs.trail
      assert.equals 3, breadcrumbs.location
      assert.same {3, 7}, [c.pos for c in *breadcrumbs.trail]

    it 'clears any buffer references for crumbs with a file reference', ->
      File.with_tmpfile (file) ->
        file.contents = '123456789'
        b1 = buffer '123456789'
        b2 = app\new_buffer!
        b2.file = file
        breadcrumbs.drop buffer: b1, pos: 3
        breadcrumbs.drop buffer: b2, pos: 5
        breadcrumbs.drop buffer: b1, pos: 7
        assert.equals 3, #breadcrumbs.trail
        assert.equals 4, breadcrumbs.location
        app\close_buffer b2
        assert.is_nil breadcrumbs.trail[2].buffer_marker
        assert.equals 3, #breadcrumbs.trail
        assert.equals 4, breadcrumbs.location

    it 'moves the current location down as necessary', ->
      File.with_tmpfile (file) ->
        file.contents = '123456789'
        b1 = buffer '123456789'
        b2 = app\new_buffer!
        b2.file = file
        breadcrumbs.drop buffer: b1, pos: 3
        breadcrumbs.drop buffer: b2, pos: 5
        breadcrumbs.drop buffer: b2, pos: 7
        assert.equals 4, breadcrumbs.location
        app\close_buffer b2
        assert.equals 1, breadcrumbs.location

  context 'memory management', ->
    it 'keeps weak references to buffers', ->
      holder = setmetatable {
        buffer: buffer '123456789\nabcdefgh'
      }, __mode: 'v'

      breadcrumbs.drop buffer: holder.buffer, pos: 3
      collectgarbage!
      assert.is_nil holder.buffer
