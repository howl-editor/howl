import Buffer, config, signal from howl
import File from howl.io
import with_tmpfile from File
append = table.insert

describe 'Buffer', ->
  buffer = (text) ->
    with Buffer {}
      .text = text

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
    b = buffer 'kept'
    b.read_only = true
    assert.equal true, b.read_only
    assert.raises 'read%-only', -> b\append 'illegal'
    assert.raises 'read%-only', -> b\insert 1, 'illegal'
    assert.raises 'read%-only', -> b.text = 'illegal'
    assert.equal 'kept', b.text
    b.read_only = false
    b\append ' yes'
    assert.equal 'kept yes', b.text

  describe '.file = <file>', ->
    b = buffer ''

    it 'sets the title to the basename of the file', ->
      with_tmpfile (file) ->
        b.file = file
        assert.equal b.title, file.basename

    describe 'when <file> exists', ->
      describe 'and the buffer is not modified', ->

        before_each ->
          b.text = 'foo'
          b.modified = false

        it 'sets the buffer text to the contents of the file', ->
          with_tmpfile (file) ->
            file.contents = 'yes sir'
            b.file = file
            assert.equal b.text, 'yes sir'

      it 'overwrites any existing buffer text even if the buffer is modified', ->
        b.text = 'foo'
        with_tmpfile (file) ->
          file.contents = 'yes sir'
          b.file = file
          assert.equal b.text, 'yes sir'

    describe 'when <file> does not exist', ->
      it 'set the buffer text to the empty string', ->
        b.text = 'foo'
        with_tmpfile (file) ->
          file\delete!
          b.file = file
          assert.equal '', b.text

    it 'marks the buffer as not modified', ->
      with_tmpfile (file) ->
        b.file = file
        assert.is_false b.modified

    it 'clears the undo history', ->
      with_tmpfile (file) ->
        b.file = file
        assert.is_false b.can_undo

  it '.eol is "\\n" by default', ->
    assert.equals '\n', buffer('').eol

  describe '.eol = <string>', ->
    it 'raises an error if the eol is unknown', ->
      assert.raises 'Unknown', -> buffer('').eol = 'foo'

  it '.properties is a table', ->
    assert.equal 'table', type buffer('').properties

  it '.data is a table', ->
    assert.equal 'table', type buffer('').data

  it '.showing is true if the buffer is currently referenced in any view', ->
    b = buffer ''
    assert.false b.showing
    b\add_view_ref!
    assert.true b.showing

  describe '.multibyte', ->
    it 'returns true if the buffer contains multibyte characters', ->
      assert.is_false buffer('vanilla').multibyte
      assert.is_true buffer('HƏllo').multibyte

    it 'is updated whenever text is inserted', ->
      b = buffer 'vanilla'
      b\append 'Bačon'
      assert.is_true b.multibyte

    it 'is updated whenever text is deleted', ->
      b = buffer 'Bačon'
      b\delete 3, 5
      assert.is_false b.multibyte

  describe '.modified_on_disk', ->
    it 'is false for a buffer with no file', ->
      assert.is_false Buffer!.modified_on_disk

    it "is true if the file's etag is changed after a load or save", ->
      file = contents: 'foo', etag: '1', basename: 'changeable', exists: true
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

    it 'is chained to the mode config when available', ->
      mode_config = config.local_proxy!
      mode = config: mode_config
      b = buffer 'config'
      b.mode = mode
      mode_config.buf_var = 'from_mode'
      assert.equal 'from_mode', b.config.buf_var

    it 'is chained to the global config when mode config is not available', ->
      b = buffer 'config'
      b.mode = {}
      assert.equal 'def value', b.config.buf_var

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
      assert.equal 'hello world', b.text

    it 'returns the position right after the inserted text', ->
      b = buffer ''
      assert.equal 6, b\append 'Bačon'

  describe 'replace(pattern, replacement)', ->
    it 'replaces all occurences of pattern with replacement', ->
      b = buffer 'hello\nuñi©ode\nworld\n'
      b\replace '[lo]', ''
      assert.equal 'he\nuñi©de\nwrd\n', b.text

    context 'when pattern contains a leading grouping', ->
      it 'replaces only the match within pattern with replacement', ->
        b = buffer 'hello\nworld\n'
        b\replace '(hel)lo', ''
        assert.equal 'lo\nworld\n', b.text

    it 'returns the number of occurences replaced', ->
      b = buffer 'hello\nworld\n'
      assert.equal 1, b\replace('world', 'editor')

  describe 'change(start_pos, end_pos, f)', ->
    it 'applies all operations as one undo for the specified region', ->
      b = buffer 'ño señor'
      b\change 4, 6, -> -- 'señ'
        b\delete 4, 6
        b\insert 'minmin', 4

      assert.equal 'ño minminor', b.text
      b\undo!
      assert.equal 'ño señor', b.text

    it 'returns the return value of <f> as its own return value', ->
      b = buffer '12345'
      ret = b\change 1, 3, ->
        'zed'

      assert.equals 'zed', ret

  describe 'undo', ->
    it 'undoes the last operation', ->
      b = buffer 'hello'
      b\delete 1, 1
      b\undo!
      assert.equal 'hello', b.text

    it 'resets the .modified flag when at synced file revision', ->
      with_tmpfile (file) ->
        b = buffer ''
        b.file = file
        b.text = 'hello'
        b\delete 1, 1
        b\save!
        b\delete 1, 1
        assert.equal true, b.modified
        b\undo!
        assert.equal false, b.modified
        b\undo!
        assert.equal true, b.modified

  describe 'redo', ->
    it 'redoes the last undo operation', ->
      b = buffer 'hello'
      b\delete 1, 1
      b\undo!
      b\redo!
      assert.equal 'ello', b.text

    it 'resets the .modified flag when at synced file revision', ->
      with_tmpfile (file) ->
        b = buffer ''
        b.file = file
        b.text = 'hello'
        b\delete 1, 1
        b\save!
        b\undo!
        b\redo!

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

  describe '.collect_revisions', ->
    context 'when set to false', ->
      it 'does not collect undo information', ->
        b = Buffer {}
        b.collect_revisions = false
        b\append 'foo!'
        assert.is_false b.can_undo

      it 'clears existing undo information', ->
        b = buffer 'zed'
        assert.is_true b.can_undo
        b.collect_revisions = false
        assert.is_false b.can_undo

  describe 'as_one_undo(f)', ->
    it 'allows for grouping actions as one undo', ->
      b = buffer 'hello'
      b\as_one_undo ->
        b\delete 1, 1
        b\append 'foo'
      b\undo!
      assert.equal 'hello', b.text

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
        text = 'line1\nline2♥\nåäö\n'
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
            b.text = 'blank  \n\nfoo \n'
            b\save!
            assert.equal 'blank  \n\nfoo \n', b.text
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

      context 'when config.ensure_newline_at_eof is true', ->
        it 'appends a newline if necessary', ->
          with_tmpfile (file) ->
            config.ensure_newline_at_eof = true
            b = buffer ''
            b.file = file
            b.text = 'look mah no newline!'
            b\save!
            assert.equal 'look mah no newline!\n', b.text
            assert.equal file.contents, b.text

      context 'when config.ensure_newline_at_eof is false', ->
        it 'does not appends a newline', ->
          with_tmpfile (file) ->
            config.ensure_newline_at_eof = false
            b = buffer ''
            b.file = file
            b.text = 'look mah no newline!'
            b\save!
            assert.equal 'look mah no newline!', b.text
            assert.equal file.contents, b.text

  describe 'save_as(file)', ->
    context 'when <file> does not exist', ->
      it 'saves the buffer content in the newly created file', ->
        with_tmpfile (file) ->
          file\delete!
          b = buffer 'new'
          b\save_as file
          assert.equal 'new', file.contents

    context 'when <file> exists', ->
      it 'overwrites any previous content with the buffer contents', ->
        with_tmpfile (file) ->
          file.contents = 'old'
          b = buffer 'new'
          b\save_as file
          assert.equal 'new', file.contents

    it 'associates the buffer with <file> henceforth', ->
      with_tmpfile (file) ->
        file.contents = 'orig'
        b = buffer ''
        b.file = file
        with_tmpfile (new_file) ->
          b.text = 'nuevo'
          b\save_as new_file
          assert.equal 'nuevo', new_file.contents
          assert.equal new_file, b.file

  describe 'byte_offset(char_offset)', ->
    it 'returns the byte offset for the given <char_offset>', ->
      b = buffer 'äåö'
      for p in *{
        {1, 1},
        {3, 2},
        {5, 3},
        {7, 4},
      }
        assert.equal p[1], b\byte_offset p[2]

    it 'adjusts out-of-bounds offsets', ->
      assert.equal 7,  buffer'äåö'\byte_offset 5
      assert.equal 7,  buffer'äåö'\byte_offset 10
      assert.equal 1,  buffer'äåö'\byte_offset 0
      assert.equal 1,  buffer'äåö'\byte_offset -1

  describe 'char_offset(byte_offset)', ->
    it 'returns the character offset for the given <byte_offset>', ->
      b = buffer 'äåö'
      for p in *{
        {1, 1},
        {3, 2},
        {5, 3},
        {7, 4},
      }
        assert.equal p[2], b\char_offset p[1]

    it 'adjusts out-of-bounds offsets', ->
      assert.equal 3, buffer'ab'\char_offset 4
      assert.equal 1, buffer'äåö'\char_offset 0
      assert.equal 1, buffer'a'\char_offset -1

  describe 'sub(start_pos, end_pos)', ->
    it 'returns the text between start_pos and end_pos, both inclusive', ->
      b = buffer 'hållö\nhållö\n'
      assert.equal 'h', b\sub(1, 1)
      assert.equal 'å', b\sub(2, 2)
      assert.equal 'hållö', b\sub(1, 5)
      assert.equal 'hållö\nhållö\n', b\sub(1, 12)
      assert.equal 'ållö', b\sub(8, 11)
      assert.equal '\n', b\sub(12, 12)
      assert.equal '\n', b\sub(12, 13)

    it 'handles negative indices by counting from end', ->
      b = buffer 'hållö\nhållö\n'
      assert.equal '\n', b\sub(-1, -1)
      assert.equal 'hållö\n', b\sub(-6, -1)
      assert.equal 'hållö\nhållö\n', b\sub(-12, -1)

    it 'returns empty string for start_pos > end_pos', ->
      b = buffer 'abc'
      assert.equal '', b\sub(2, 1)

    it 'handles out-of-bounds offsets gracefully', ->
      assert.equals '', buffer'abc'\sub 4, 6
      assert.equals 'abc', buffer'abc'\sub 1, 6

  describe 'find(pattern [, init ])', ->
    it 'searches forward', ->
      b = buffer 'ä öx'
      assert.same { 1, 4 }, { b\find 'ä öx' }
      assert.same { 2, 3 }, { b\find ' ö' }
      assert.same { 3, 4 }, { b\find 'öx' }
      assert.same { 4, 4 }, { b\find 'x' }

    it 'searches forward from init when specified', ->
      b = buffer 'öåååö'
      assert.same { 2, 3 }, { b\find 'åå', 2 }
      assert.same { 3, 4 }, { b\find 'åå', 3 }
      assert.is_nil b\find('åå', 4)

    it 'negative init specifies offset from end', ->
      b = buffer 'öååååö'
      assert.same { 4, 5 }, { b\find 'åå', -3 }
      assert.same { 2, 3 }, { b\find 'åå', -5 }
      assert.is_nil b\find('åå', -2)

    it 'returns nil for out of bounds init', ->
      b = buffer 'abcde'
      assert.is_nil b\find('a', -6)
      assert.is_nil b\find('a', 6)

  describe 'rfind(pattern [, init ])', ->
    it 'searches backward from end', ->
      b = buffer 'äöxöx'
      assert.same { 1, 3 }, { b\rfind 'äöx' }
      assert.same { 4, 5 }, { b\rfind 'öx' }
      assert.same { 5, 5 }, { b\rfind 'x' }

    it 'searches backward from init when specified', ->
      b = buffer 'öååååö'
      assert.same { 4, 5 }, { b\rfind 'åå', 5 }
      assert.same { 3, 4 }, { b\rfind 'åå', 4 }
      assert.is_nil b\rfind('åå', 2)

    it 'negative init specifies offset from end', ->
      b = buffer 'öååååö'
      assert.same { 4, 5 }, { b\rfind 'åå', -2 }
      assert.same { 2, 3 }, { b\rfind 'åå', -4 }
      assert.is_nil b\rfind('åå', -5)

    it 'returns nil for out of bounds init', ->
      b = buffer 'abcde'
      assert.is_nil b\rfind('a', -6)
      assert.is_nil b\rfind('a', 6)

  describe 'reload(force = false)', ->
    it 'reloads the buffer contents from file and returns true', ->
      with_tmpfile (file) ->
        b = buffer ''
        file.contents = 'hello'
        b.file = file
        file.contents = 'there'
        assert.is_true b\reload!
        assert.equal 'there', b.text

    it 'raises an error if the buffer is not associated with a file', ->
      assert.raises 'file', -> Buffer!\reload!

    context 'when the buffer is modified', ->
      it 'leaves the buffer alone and returns false', ->
        with_tmpfile (file) ->
          b = buffer ''
          file.contents = 'hello'
          b.file = file
          b\append ' world'
          file.contents = 'there'
          assert.is_false b\reload!
          assert.equal 'hello world', b.text

      it 'specifying <force> as true reloads the buffer anyway', ->
        with_tmpfile (file) ->
          b = buffer ''
          file.contents = 'hello'
          b.file = file
          b\append ' world'
          file.contents = 'there'
          assert.is_true b\reload true
          assert.equal 'there', b.text

  it '#buffer returns the number of characters in the buffer', ->
    assert.equal 5, #buffer('hello')
    assert.equal 3, #buffer('åäö')

  it 'tostring(buffer) returns the buffer title', ->
    b = buffer 'hello'
    b.title = 'foo'
    assert.equal tostring(b), 'foo'

  describe '.add_view_ref()', ->
    it 'increments the number of viewers', ->
      b = buffer ''
      b\add_view_ref!
      assert.equal 1, b.viewers

  describe '.remove_view_ref()', ->
    it 'decrements the number of viewers', ->
      b = buffer ''
      b\add_view_ref!
      b\remove_view_ref!
      assert.equal 0, b.viewers

  describe 'titles', ->
    it 'uses file basename as the default title', ->
      b = Buffer {}
      b.file = File('/path/to/file.ext')
      assert.equal b.title, 'file.ext'

    it 'setting title explicitly overrides default title', ->
      b = Buffer {}
      b.file = File('/path/to/file.ext')
      b.title = 'be something else'
      assert.equal b.title, 'be something else'

  describe 'signals', ->
    it 'buffer-saved is fired whenever a buffer is saved', ->
      with_signal_handler 'buffer-saved', nil, (handler) ->
        b = buffer 'foo'
        with_tmpfile (file) ->
          b.file = file
          b\save!

        assert.spy(handler).was_called!

    it 'text-inserted is fired whenever text is inserted into a buffer', ->
      with_signal_handler 'text-inserted', nil, (handler) ->
        b = buffer 'foo'
        b\append 'bar'
        assert.spy(handler).was_called!

    it 'text-deleted is fired whenever text is deleted from buffer', ->
      with_signal_handler 'text-inserted', nil, (handler) ->
        b = buffer 'foo'
        b\delete 1, 2
        assert.spy(handler).was_called!

    it 'text-changed is fired whenever text is change:d from buffer', ->
      with_signal_handler 'text-changed', nil, (handler) ->
        b = buffer 'foo'
        b\change 1, 2, ->
          b\delete 1, 1
        assert.spy(handler).was_called!

    it 'buffer-modified is fired whenever a buffer is modified', ->
      with_signal_handler 'buffer-modified', nil, (handler) ->
        b = buffer 'foo'
        b\append 'bar'
        assert.spy(handler).was_called!

    it 'buffer-reloaded is fired whenever a buffer is reloaded', ->
      with_signal_handler 'buffer-reloaded', nil, (handler) ->
        with_tmpfile (file) ->
          b = buffer 'foo'
          b.file = file
          b\reload!
          assert.spy(handler).was_called!

    it 'buffer-mode-set is fired whenever a buffer has its mode set', ->
      with_signal_handler 'buffer-mode-set', nil, (handler) ->
        b = buffer 'foo'
        b.mode = {}
        assert.spy(handler).was_called!

    it 'buffer-title-set is fired whenever a buffer has its title set', ->
      with_signal_handler 'buffer-title-set', nil, (handler) ->
        b = buffer 'foo'
        b.title = 'Sir Buffer'
        assert.spy(handler).was_called!

  context 'resource management', ->
    it 'buffers are collected properly', ->
      b = buffer 'foobar'
      buffers = setmetatable { b }, __mode: 'v'
      b = nil
      collectgarbage!
      assert.is_nil buffers[1]

    it 'memory usage is stable', ->
      assert_memory_stays_within '5Kb', 30, ->
        buffer 'collect me!'

