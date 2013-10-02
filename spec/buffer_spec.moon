import Buffer, Scintilla, config, signal from howl
import File from howl.fs

describe 'Buffer', ->
  local sci

  before_each -> sci = Scintilla!

  buffer = (text) ->
    with Buffer {}
      .text = text

  describe 'creation', ->
    context 'when sci parameter is specified', ->
      it 'attaches .sci and .doc to the Scintilla instance', ->
        sci.get_doc_pointer = -> 'docky'
        b = Buffer {}, sci
        assert.equal b.doc, 'docky'
        assert.equal b.sci, sci

  it '.text allows setting and retrieving the buffer text', ->
    b = Buffer {}
    assert.equal b.text, ''
    b.text = 'Ipsum'
    assert.equal 'Ipsum', b.text

  it '.size returns the size of the buffer text, in bytes', ->
    assert.equal buffer('hello').size, 5
    assert.equal buffer('åäö').size, 6

  it '.length returns the size of the buffer text, in characters', ->
    assert.equal 5, buffer('hello').length
    assert.equal 3, buffer('åäö').length

  it '.modified indicates and allows setting the modified status', ->
    b = Buffer {}
    assert.is_false b.modified
    b.text = 'hello'
    assert.is_true b.modified
    b.modified = false
    assert.is_false b.modified
    b.modified = true
    assert.is_true b.modified
    assert.equal b.text, 'hello' -- toggling should not have changed text

  it '.read_only can be set to mark the buffer as read-only', ->
    b = Buffer!
    b.read_only = true
    assert.equal true, b.read_only
    b\append 'illegal'
    assert.equal '', b.text
    b.read_only = false
    b\append 'yes'
    assert.equal 'yes', b.text

  describe '.mode = <mode>', ->
    context 'when <mode> has a lexer', ->
      it 'updates all embedding scis to use container lexing', ->
        b = Buffer!
        b\add_sci_ref sci
        assert.equal Scintilla.SCLEX_NULL, sci\get_lexer!
        b.mode = lexer: -> {}
        assert.equal Scintilla.SCLEX_CONTAINER, sci\get_lexer!

    context 'when <mode> does not have a lexer', ->
      it 'updates all embedding scis to use null lexing', ->
        b = Buffer lexer: -> {}
        b\add_sci_ref sci
        assert.equal Scintilla.SCLEX_CONTAINER, sci\get_lexer!
        b.mode = {}
        assert.equal Scintilla.SCLEX_NULL, sci\get_lexer!

  describe '.file = <file>', ->
    b = buffer ''

    it 'sets the title to the basename of the file', ->
      with_tmpfile (file) ->
        b.file = file
        assert.equal b.title, file.basename

    describe 'when <file> exists', ->
      describe 'and the buffer is not modified', ->

        before ->
          b.text = 'foo'
          b.modified = false

        it 'sets the buffer text to the contents of the file', ->
          with_tmpfile (file) ->
            file.contents = 'yes sir'
            b.file = file
            assert.equal b.text, 'yes sir'

        it 'marks the buffer as not modified', ->
          with_tmpfile (file) ->
            b.file = file
            assert.is_false b.modified

        it 'clears the undo history', ->
          with_tmpfile (file) ->
            b.file = file
            assert.is_false b.can_undo

      it 'keeps the existing buffer text if the buffer is modified', ->
        b.text = 'foo'
        with_tmpfile (file) ->
          file.contents = 'yes sir'
          b.file = file
          assert.equal b.text, 'foo'

    it 'keeps the existing buffer text if the file does not exist', ->
      b.text = 'foo'
      with_tmpfile (file) ->
        file\delete!
        b.file = file
        assert.equal b.text, 'foo'

  it '.eol returns the current line ending', ->
    b = buffer ''

    b.sci\set_eolmode Scintilla.SC_EOL_CRLF
    assert.equal b.eol, '\r\n'

    b.sci\set_eolmode Scintilla.SC_EOL_LF
    assert.equal b.eol, '\n'

    b.sci\set_eolmode Scintilla.SC_EOL_CR
    assert.equal b.eol, '\r'

  describe '.eol = <string>', ->
    it 'set the the current line ending', ->
      b = buffer ''

      b.eol = '\n'
      assert.equal b.sci\get_eolmode!, Scintilla.SC_EOL_LF

      b.eol = '\r\n'
      assert.equal b.sci\get_eolmode!, Scintilla.SC_EOL_CRLF

      b.eol = '\r'
      assert.equal b.sci\get_eolmode!, Scintilla.SC_EOL_CR

    it 'raises an error if the eol is unknown', ->
      assert.raises 'Unknown', -> buffer('').eol = 'foo'

  it '.properties is a table', ->
    assert.equal 'table', type buffer('').properties

  it '.data is a table', ->
    assert.equal 'table', type buffer('').data

  it '.showing is true if the buffer is currently referenced in any sci', ->
    b = buffer ''
    assert.false b.showing
    b\add_sci_ref sci
    assert.true b.showing

  it '.last_shown returns a timestamp indicating when it was last shown', ->
    b = buffer ''
    assert.is_nil b.last_shown
    ts = os.time!
    b\add_sci_ref sci
    assert.is_true b.last_shown >= ts
    b\remove_sci_ref sci
    assert.is_true b.last_shown <= os.time!

  describe '.multibyte', ->
    it 'returns true if the buffer contains multibyte characters', ->
      assert.is_false buffer('vanilla').multibyte
      assert.is_true buffer('HƏllo').multibyte

    it 'is updated whenever text is inserted', ->
      b = buffer 'vanilla'
      b\append 'Bačon'
      assert.is_true b.multibyte

    it 'is unset whenever a previously multibyte buffer has its length calculated', ->
      b = buffer('HƏllo')
      b\delete 2, 2
      b.length
      assert.is_false b.multibyte

  describe '.modified_on_disk', ->
    it 'is false for a buffer with no file', ->
      assert.is_false Buffer!.modified_on_disk

    it "is true if the file's etag is changed after a load or save", ->
      file = contents: 'foo', etag: '1', basename: 'changeable'
      b = Buffer!
      b.file = file
      file.etag = '2'
      assert.is_true b.modified_on_disk
      b\save!
      assert.is_false b.modified_on_disk

  describe '.config', ->
    config.define name: 'buf_var', description: 'some var', default: 'def value'

    it 'allows reading and writing (local) variables', ->
      b = buffer 'config'
      assert.equal 'def value', b.config.buf_var
      b.config.buf_var = 123
      assert.equal 123, b.config.buf_var
      assert.equal 'def value', config.buf_var

    it 'is chained to the mode config', ->
      mode_config = config.local_proxy!
      mode = config: mode_config
      b = buffer 'config'
      b.mode = mode
      mode_config.buf_var = 'from_mode'
      assert.equal 'from_mode', b.config.buf_var

  describe 'delete(start_pos, end_pos)', ->
    it 'deletes the specified range, inclusive', ->
      b = buffer 'ño örf'
      b\delete 2, 4
      assert.equal 'ñrf', b.text

    it 'does nothing if end_pos is smaller than start_pos', ->
      b = buffer 'hello'
      b\delete 2, 1
      assert.equal 'hello', b.text

  describe 'insert(text, pos)', ->
    it 'inserts text at pos', ->
      b = buffer 'ño señor'
      b\insert 'me gusta ', 4
      assert.equal 'ño me gusta señor', b.text

    it 'returns the position right after the inserted text', ->
      b = buffer ''
      assert.equal 6, b\insert 'Bačon', 1

  describe 'append(text)', ->
    it 'appends the specified text', ->
      b = buffer 'hello'
      b\append ' world'
      assert.equal b.text, 'hello world'

    it 'returns the position right after the inserted text', ->
      b = buffer ''
      assert.equal 6, b\append 'Bačon'

  describe 'replace(pattern, replacement)', ->
    it 'replaces all occurences of pattern with replacement', ->
      b = buffer 'hello\nuñi©ode\nworld\n'
      b\replace '[lo]', ''
      assert.equal 'he\nuñi©de\nwrd\n', b.text

    context 'when pattern contains a grouping', ->
      it 'replaces only the match within pattern with replacement', ->
        b = buffer 'hello\nworld\n'
        b\replace '(hel)lo', ''
        assert.equal 'lo\nworld\n', b.text

    it 'returns the number of occurences replaced', ->
      b = buffer 'hello\nworld\n'
      assert.equal 1, b\replace('world', 'editor')

  describe 'destroy()', ->
    context 'when no sci is passed and a doc is created in the constructor', ->
      it 'releases the scintilla document', ->
        b = buffer 'reap_me'
        rawset b, 'sci', Spy as_null_object: true
        b\destroy!
        assert.is_true b.sci.release_document.called

    context 'when a sci is passed and a doc is provided in the constructor', ->
      it 'an error is raised since the buffer is considered as currently showing', ->
        sci.get_doc_pointer = -> 'doc'
        sci.release_document = spy.new -> nil
        b = Buffer {}, sci
        assert.raises 'showing', -> b\destroy!
        assert.spy(sci.release_document).was_not.called!

    it 'raises an error if the buffer is currently showing', ->
      b = buffer 'not yet'
      b\add_sci_ref sci
      assert.raises 'showing', -> b\destroy!

    it 'a destroyed buffer raises an error upon subsequent operations', ->
      b = buffer 'reap_me'
      b\destroy!
      assert.raises 'destroyed', -> b.size
      assert.raises 'destroyed', -> b.lines
      assert.raises 'destroyed', -> b\append 'foo'

  it '.destroyed is true if the buffer is destroyed and false otherwise', ->
    b = buffer 'shoot_me'
    assert.is_false b.destroyed
    b\destroy!
    assert.is_true b.destroyed

  it 'undo undoes the last operation', ->
    b = buffer 'hello'
    b\delete 1, 1
    b\undo!
    assert.equal b.text, 'hello'

  it '.can_undo returns true if undo is possible, and false otherwise', ->
    b = Buffer {}
    assert.is_false b.can_undo
    b.text = 'bar'
    assert.is_true b.can_undo
    b\undo!
    assert.is_false b.can_undo

  describe '.can_undo = <bool>', ->
    it 'setting it to false removes any undo history', ->
      b = buffer 'hello'
      assert.is_true b.can_undo
      b.can_undo = false
      assert.is_false b.can_undo
      b\undo!
      assert.equal b.text, 'hello'

    it 'setting it to true is a no-op', ->
      b = buffer 'hello'
      assert.is_true b.can_undo
      b.can_undo = true
      assert.is_true b.can_undo
      b\undo!
      b.can_undo = true
      assert.is_false b.can_undo

  describe 'as_one_undo(f)', ->
    it 'allows for grouping actions as one undo', ->
      b = buffer 'hello'
      b\as_one_undo ->
        b\delete 1, 1
        b\append 'foo'
      b\undo!
      assert.equal b.text, 'hello'

    context 'when f raises an error', ->
      it 'propagates the error', ->
        b = buffer 'hello'
        assert.raises 'oh my',  ->
          b\as_one_undo -> error 'oh my'

      it 'ends the undo transaction', ->
        b = buffer 'hello'
        assert.error -> b\as_one_undo ->
          b\delete 1, 1
          error 'oh noes what happened?!?'
        b\append 'foo'
        b\undo!
        assert.equal b.text, 'ello'

  describe 'save()', ->
    context 'when a file is assigned', ->
      it 'stores the contents of the buffer in the assigned file', ->
        text = 'line1\nline2♥\nåäö'
        b = buffer text
        with_tmpfile (file) ->
          b.file = file
          b.text = text
          b\save!
          assert.equal text, file.contents

      it 'clears the modified flag', ->
        with_tmpfile (file) ->
          b = buffer 'foo'
          b.file = file
          b\append ' bar'
          assert.is_true b.modified
          b\save!
          assert.is_false b.modified

      context 'when config.strip_trailing_whitespace is false', ->
        it 'does not strip trailing whitespace before saving', ->
          with_tmpfile (file) ->
            config.strip_trailing_whitespace = false
            b = buffer ''
            b.file = file
            b.text = 'blank  \n\nfoo '
            b\save!
            assert.equal 'blank  \n\nfoo ', b.text
            assert.equal file.contents, b.text

      context 'when config.strip_trailing_whitespace is true', ->
        it 'strips trailing whitespace at the end of lines before saving', ->
          with_tmpfile (file) ->
            config.strip_trailing_whitespace = true
            b = buffer ''
            b.file = file
            b.text = 'åäö  \n\nfoo  \n  '
            b\save!
            assert.equal 'åäö\n\nfoo\n', b.text
            assert.equal file.contents, b.text

  describe 'byte_offset(...)', ->
    it 'returns byte offsets for all character offsets passed as parameters', ->
      assert.same {1, 3, 5, 7}, { buffer'äåö'\byte_offset 1, 2, 3, 4 }

    it 'accepts non-increasing offsets', ->
      assert.same {1, 1}, { buffer'ab'\byte_offset 1, 1 }

    it 'raises an error for decreasing offsets', ->
      assert.raises 'Decreasing offset', -> buffer'äåö'\byte_offset 2, 1

    it 'raises error for out-of-bounds offsets', ->
      assert.has_error -> buffer'äåö'\byte_offset 5
      assert.has_error -> buffer'äåö'\byte_offset 0
      assert.has_error -> buffer'a'\byte_offset -1

    it 'when parameters is a table, it returns a table for all offsets within that table', ->
      assert.same {1, 3, 5}, buffer'äåö'\byte_offset { 1, 2, 3 }

  describe 'char_offset(...)', ->
    it 'returns character offsets for all byte offsets passed as parameters', ->
      assert.same {1, 2, 3, 4}, { buffer'äåö'\char_offset 1, 3, 5, 7 }

    it 'accepts non-increasing offsets', ->
      assert.same {2, 2}, { buffer'ab'\char_offset 2, 2 }

    it 'raises an error for decreasing offsets', ->
      assert.raises 'Decreasing offset', -> buffer'äåö'\char_offset 3, 1

    it 'raises error for out-of-bounds offsets', ->
      assert.has_error -> buffer'ab'\char_offset 4
      assert.has_error -> buffer'äåö'\char_offset 0
      assert.has_error -> buffer'a'\char_offset -1

    it 'when parameters is a table, it returns a table for all offsets within that table', ->
      assert.same {1, 2, 3, 4}, buffer'äåö'\char_offset { 1, 3, 5, 7 }

  describe 'reload()', ->
    it 'reloads the buffer contents from file', ->
      with_tmpfile (file) ->
        b = buffer ''
        file.contents = 'hello'
        b.file = file
        file.contents = 'there'
        b\reload!
        assert.equal 'there', b.text

    it 'raises an error if the buffer is not associated with a file', ->
      assert.raises 'file', -> Buffer!\reload!

  it '#buffer returns the number of characters in the buffer', ->
    assert.equal 5, #buffer('hello')
    assert.equal 3, #buffer('åäö')

  it 'tostring(buffer) returns the buffer title', ->
    b = buffer 'hello'
    b.title = 'foo'
    assert.equal tostring(b), 'foo'

  describe '.add_sci_ref(sci)', ->
    it 'adds the specified sci to .scis', ->
      b = buffer ''
      b\add_sci_ref sci
      assert.same b.scis, { sci }

    it 'sets .sci to the specified sci', ->
      b = buffer ''
      b\add_sci_ref sci
      assert.equal b.sci, sci

    it 'sets the sci lexer to container if the mode has a lexer', ->
      b = buffer ''
      b.mode.lexer = -> {}
      sci\set_lexer Scintilla.SCLEX_NULL
      b\add_sci_ref sci
      assert.equal Scintilla.SCLEX_CONTAINER, sci\get_lexer!

    it 'sets the sci lexer to null if mode has no lexer', ->
      b = buffer ''
      sci\set_lexer Scintilla.SCLEX_CONTAINER
      b\add_sci_ref sci
      assert.equal Scintilla.SCLEX_NULL, sci\get_lexer!

  describe '.remove_sci_ref(sci)', ->
    it 'removes the specified sci from .scis', ->
      b = buffer ''
      b\add_sci_ref sci
      b\remove_sci_ref sci
      assert.same b.scis, {}

    it 'sets .sci to some other sci if they were previously the same', ->
      sci2 = Scintilla!
      b = buffer ''
      b\add_sci_ref sci
      b\add_sci_ref sci2
      assert.equal b.sci, sci2
      b\remove_sci_ref sci2
      assert.equal b.sci, sci

  describe 'ensuring that buffer titles are globally unique', ->
    context 'when setting a file for a buffer', ->
      it 'prepends to the title as many parent directories as needed for uniqueness', ->
        b1 = Buffer {}
        b2 = Buffer {}
        b3 = Buffer {}
        with_tmpdir (dir) ->
          sub1 = dir\join('sub1')
          sub1\mkdir!
          sub2 = dir\join('sub2')
          sub2\mkdir!
          f1 = sub1\join('file.foo')
          f2 = sub2\join('file.foo')
          f1\touch!
          f2\touch!
          b1.file = f1
          b2.file = f2
          assert.equal b2.title, 'sub2' .. File.separator .. 'file.foo'

          sub_sub = sub1\join('sub2')
          sub_sub\mkdir!
          f3 = sub_sub\join('file.foo')
          f3\touch!
          b3.file = f3
          assert.equal b3.title, 'sub1' .. File.separator .. b2.title

      it 'does not unneccesarily transform the title when setting the same file for a buffer', ->
        b = Buffer!
        with_tmpfile (file) ->
          b.file = file
          title = b.title
          b.file = file
          assert.equal title, b.title

    context 'when setting the title explicitly', ->
      it 'appends a counter number in the format <number> to the title', ->
        b1 = Buffer {}
        b2 = Buffer {}
        b1.title = 'Title'
        b2.title = 'Title'
        assert.equal b2.title, 'Title<2>'

  describe 'resource management', ->
    it 'scintilla documents are released whenever the buffer is garbage collected', ->
      release = Spy!
      orig_release = Scintilla.release_document
      Scintilla.release_document = release
      b = Buffer {}
      doc = b.doc
      b = nil
      collectgarbage!
      Scintilla.release_document = orig_release
      assert.equal release.called_with[2], doc

    it 'buffers are collected as they should', ->
      b = Buffer {}
      bufs = setmetatable {}, __mode: 'v'
      append bufs, b
      b = nil
      collectgarbage!
      assert.is_nil bufs[1]

  describe 'signals', ->
    it 'buffer-saved is fired whenever a buffer is saved', ->
      handler = spy.new -> true
      signal.connect 'buffer-saved', handler
      b = buffer 'foo'
      with_tmpfile (file) ->
        b.file = file
        b\save!

      signal.disconnect 'buffer-saved', handler
      assert.spy(handler).was_called!

    it 'buffer-modified is fired whenever a buffer is modified', ->
      handler = spy.new -> true
      b = buffer 'foo'
      signal.connect 'buffer-modified', handler
      b\append 'bar'
      b\delete 1, 2
      signal.disconnect 'buffer-modified', handler
      assert.spy(handler).was_called 2

    it 'buffer-reloaded is fired whenever a buffer is reloaded', ->
      handler = spy.new -> true
      with_tmpfile (file) ->
        b = buffer 'foo'
        b.file = file
        signal.connect 'buffer-reloaded', handler
        b\reload!
        signal.disconnect 'buffer-reloaded', handler
        assert.spy(handler).was_called!

    it 'buffer-title-set is fired whenever a buffer has its title set', ->
      handler = spy.new -> true
      b = buffer 'foo'
      signal.connect 'buffer-title-set', handler
      b.title = 'Sir Buffer'
      signal.disconnect 'buffer-title-set', handler
      assert.spy(handler).was_called!
