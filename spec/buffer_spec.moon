import Buffer, Scintilla, config from lunar
import File from lunar.fs

describe 'Buffer', ->
  buffer = (text) ->
    with Buffer {}
      .text = text

  describe 'creation', ->
    it 'Buffer(mode) raises an error if mode is not given', ->
      assert.error -> Buffer!

    context 'when sci parameter is specified', ->
      it 'attaches .sci and .doc to the Scintilla instance', ->
        sci = get_doc_pointer: -> 'docky'
        b = Buffer {}, sci
        assert.equal b.doc, 'docky'
        assert.equal b.sci, sci

  it '.text allows setting and retrieving the buffer text', ->
    b = Buffer {}
    assert.equal b.text, ''
    b.text = 'Ipsum'
    assert.equal b.text, 'Ipsum'

  it '.size returns the size of the buffer text, in bytes', ->
    assert.equal buffer('hello').size, 5

  it '.dirty indicates and allows setting the modified status', ->
    b = Buffer {}
    assert.is_false b.dirty
    b.text = 'hello'
    assert.is_true b.dirty
    b.dirty = false
    assert.is_false b.dirty
    b.dirty = true
    assert.is_true b.dirty
    assert.equal b.text, 'hello' -- toggling should not have changed text

  describe '.file = <file>', ->
    b = buffer ''

    it 'sets the title to the basename of the file', ->
      with_tmpfile (file) ->
        b.file = file
        assert.equal b.title, file.basename

    it 'sets the buffer text to the contents of the file', ->
      b.text = 'foo'
      with_tmpfile (file) ->
        file.contents = 'yes sir'
        b.file = file
        assert.equal b.text, 'yes sir'

    it 'marks the buffer as not dirty', ->
      b.dirty = true
      with_tmpfile (file) ->
        b.file = file
        assert.is_false b.dirty

    it 'clears the undo history', ->
      b.text = 'foo'
      with_tmpfile (file) ->
        b.file = file
        assert.is_false b.can_undo

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

  it '.chunk(start_pos, length) returns a chunk for the specified range', ->
    b = buffer 'chunky bacon'
    chunk = b\chunk(8, 3)
    assert.equal 'bac', chunk.text

  it '.word_at(pos) returns a chunk for the word at <pos>', ->
    b = buffer '"Hello", said Mr.Bacon'
    assert.equal '', b\word_at(1).text
    assert.equal 'Hello', b\word_at(2).text
    assert.equal 'Hello', b\word_at(6).text
    assert.equal 'Hello', b\word_at(4).text
    assert.equal '', b\word_at(8).text
    assert.equal 'said', b\word_at(14).text
    assert.equal 'Mr', b\word_at(16).text
    assert.equal 'Bacon', b\word_at(19).text

  describe 'insert(text, pos)', ->
    it 'inserts text at pos', ->
      b = buffer 'heo'
      b\insert 'll', 3
      assert.equal b.text, 'hello'

    it 'returns the position right after the inserted text', ->
      b = buffer ''
      assert.equal b\insert('hej', 1), 4

  it 'append(text) appends the specified text', ->
    b = buffer 'hello'
    b\append ' world'
    assert.equal b.text, 'hello world'

  describe '#replace(pattern, replacement)', ->
    it 'replaces all occurences of pattern with replacement', ->
      b = buffer 'hello\nworld\n'
      b\replace '[lo]', ''
      assert.equal 'he\nwrd\n', b.text

    context 'when pattern contains a grouping', ->
      it 'replaces only the match within pattern with replacement', ->
        b = buffer 'hello\nworld\n'
        b\replace '(hel)lo', ''
        assert.equal 'lo\nworld\n', b.text

    it 'returns the number of occurences replaced', ->
      b = buffer 'hello\nworld\n'
      assert.equal 1, b\replace('world', 'editor')

  describe 'destroy()', ->
    context 'when no sci is passed and a doc is created', ->
      it 'releases the scintilla document', ->
        b = buffer 'reap_me'
        rawset b, 'sci', Spy as_null_object: true
        b\destroy!
        assert.is_true b.sci.release_document.called

    context 'when a sci is passed and a doc is provided', ->
      it 'does not release the scintilla document', ->
        sci = get_doc_pointer: (-> 'doc'), release_document: Spy!
        b = Buffer {}, sci
        b\destroy!
        assert.is_false sci.release_document.called

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

  it 'delete deletes the specified number of characters', ->
    b = buffer 'hello'
    b\delete 2, 2
    assert.equal b.text, 'hlo'

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

      it 'clears the dirty flag', ->
        with_tmpfile (file) ->
          b = buffer 'foo'
          b.file = file
          b\append ' bar'
          assert.is_true b.dirty
          b\save!
          assert.is_false b.dirty

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
            b.text = 'blank  \n\nfoo '
            b\save!
            assert.equal 'blank\n\nfoo', b.text
            assert.equal file.contents, b.text

  it '#buffer returns the same as buffer.size', ->
    b = buffer 'hello'
    assert.equal #b, b.size

  it 'tostring(buffer) returns the buffer title', ->
    b = buffer 'hello'
    b.title = 'foo'
    assert.equal tostring(b), 'foo'

  describe '.add_sci_ref(sci)', ->
    it 'adds the specified sci to .scis', ->
      sci = {}
      b = buffer ''
      b\add_sci_ref sci
      assert.same b.scis, { sci }

    it 'sets .sci to the specified sci', ->
      sci = {}
      b = buffer ''
      b\add_sci_ref sci
      assert.equal b.sci, sci

  describe '.remove_sci_ref(sci)', ->
    it 'removes the specified sci from .scis', ->
      sci = {}
      b = buffer ''
      b\add_sci_ref sci
      b\remove_sci_ref sci
      assert.same b.scis, {}

    it 'sets .sci to some other sci if they were previously the same', ->
      sci = {}
      sci2 = {}
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
