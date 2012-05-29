import File from vilu.fs

describe 'File', ->
  describe '.tmpfile', ->
    it 'returns a file instance pointing to an existing file', ->
      assert_true File.tmpfile!.exists

  describe '.is_absolute', ->
    it 'returns true if the given path is absolute', ->
      assert_true File.is_absolute '/bin/ls'
      assert_true File.is_absolute 'c:\\\\bin\\ls'

    it 'returns false if the given path is absolute', ->
      assert_false File.is_absolute 'bin/ls'
      assert_false File.is_absolute 'bin\\ls'

  expect '.basename returns the basename of the path', ->
      assert_equal File('/foo/base.ext').basename, 'base.ext'

  expect '.extension returns the extension of the path', ->
      assert_equal File('/foo/base.ext').extension, 'ext'

  expect '.uri returns an URI representing the path', ->
      assert_equal File('/foo.txt').uri, 'file:///foo.txt'

  expect '.exists returns true if the path exists', ->
    file = File.tmpfile!
    assert_true file.exists

  describe 'contents', ->
    expect 'assigning a string writes the string to the file', ->
      file = File.tmpfile!
      file.contents = 'hello world'
      f = io.open file.path
      read_back = f\read '*all'
      f\close!
      assert_equal read_back, 'hello world'

    it 'returns the contents of the file', ->
      file = File.tmpfile!
      f = io.open file.path, 'w'
      f\write 'hello world'
      f\close!
      assert_equal file.contents, 'hello world'

  expect '.parent return the parent of the file', ->
    assert_equal File('/bin/ls').parent.path, '/bin'

  expect '.children returns a table of children', ->
    file = File.tmpfile!
    file\delete!
    file\mkdir!
    file\join('child1')\mkdir!
    file\join('child2')\touch!
    kids = file.children
    table.sort kids, (a,b) -> a.path < b.path
    assert_table_equal [v.basename for v in *kids], { 'child1', 'child2' }

  expect 'join returns a new file representing the specified child', ->
    assert_equal File('/bin')\join('ls').path, '/bin/ls'

  describe 'mkdir', ->
    it 'creates a directory for the path specified by the file', ->
      file = File.tmpfile!
      file\delete!
      file\mkdir!
      assert_true file.exists and file.is_directory

  describe 'mkdir_p', ->
    it 'creates a directory for the path specified by the file, including parents', ->
      file = File.tmpfile!
      file\delete!
      file = file\join 'sub/foo'
      file\mkdir_p!
      assert_true file.exists and file.is_directory

  describe 'delete', ->
    it 'deletes the target file', ->
      file = File.tmpfile!
      file\touch! if not file.exists
      file\delete!
      assert_false file.exists

    it 'raise an error if the file does not exist', ->
      file = File.tmpfile!
      file\delete! if file.exists
      assert_error -> file\delete!

  describe 'touch', ->
    it 'creates the file if does not exist', ->
      file = File.tmpfile!
      file\delete!
      file\touch!
      assert_true file.exists

    it 'raise an error if the file could not be created', ->
      file = File '/no/does/not/exist'
      file\delete! if file.exists
      assert_error -> file\touch!

  describe 'meta methods', ->
    it '/ and .. joins the file with the specified argument', ->
      file = File('/bin')
      assert_equal (file / 'ls').path, '/bin/ls'
      assert_equal (file .. 'ls').path, '/bin/ls'

    it 'tostring returns the result of File.tostring', ->
      file = File '/bin/ls'
      assert_equal file\tostring!, tostring file

    it '== returns true if the files point to the same path', ->
      assert_equal File('/bin/ls'), File('/bin/ls')

