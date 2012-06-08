import File from vilu.fs

describe 'File', ->

  describe '.tmpfile', ->
    it 'returns a file instance pointing to an existing file', ->
      file = File.tmpfile!
      assert_true file.exists
      file\delete!

  describe '.tmpdir', ->
    it 'returns a file instance pointing to an existing directory', ->
      file = File.tmpdir!
      assert_true file.exists
      assert_true file.is_directory
      file\delete_all!

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
    with_tmpfile (file) -> assert_true file.exists

  describe 'contents', ->
    expect 'assigning a string writes the string to the file', ->
      with_tmpfile (file) ->
        file.contents = 'hello world'
        f = io.open file.path
        read_back = f\read '*all'
        f\close!
        assert_equal read_back, 'hello world'

    it 'returns the contents of the file', ->
      with_tmpfile (file) ->
        f = io.open file.path, 'w'
        f\write 'hello world'
        f\close!
        assert_equal file.contents, 'hello world'

  expect '.parent return the parent of the file', ->
    assert_equal File('/bin/ls').parent.path, '/bin'

  expect '.children returns a table of children', ->
    with_tmpdir (dir) ->
      dir\join('child1')\mkdir!
      dir\join('child2')\touch!
      kids = dir.children
      table.sort kids, (a,b) -> a.path < b.path
      assert_table_equal [v.basename for v in *kids], { 'child1', 'child2' }

  expect 'join returns a new file representing the specified child', ->
    assert_equal File('/bin')\join('ls').path, '/bin/ls'

  it 'relative_to_parent returns a path relative to the specified parent', ->
    parent = File '/bin'
    file = File '/bin/ls'
    assert_equal 'ls', file\relative_to_parent(parent)

  describe 'mkdir', ->
    it 'creates a directory for the path specified by the file', ->
      with_tmpfile (file) ->
        file\delete!
        file\mkdir!
        assert_true file.exists and file.is_directory

  describe 'mkdir_p', ->
    it 'creates a directory for the path specified by the file, including parents', ->
      with_tmpfile (file) ->
        file\delete!
        file = file\join 'sub/foo'
        file\mkdir_p!
        assert_true file.exists and file.is_directory

  describe 'delete', ->
    it 'deletes the target file', ->
      with_tmpfile (file) ->
        file\delete!
        assert_false file.exists

    it 'raise an error if the file does not exist', ->
      file = File.tmpfile!
      file\delete!
      assert_error -> file\delete!

  it 'rm and unlink is an alias for delete', ->
    assert_equal File.rm, File.delete
    assert_equal File.unlink, File.delete

  describe 'delete_all', ->
    context 'for a regular file', ->
      it 'deletes the target file', ->
        with_tmpfile (file) ->
          file\delete_all!
          assert_false file.exists

    context 'for a directory', ->
      it 'deletes the directory and all sub entries', ->
        with_tmpdir (dir) ->
          dir\join('child1')\mkdir!
          dir\join('child1/sub_child')\touch!
          dir\join('child2')\touch!
          dir\delete_all!
          assert_false dir.exists

    it 'raise an error if the file does not exist', ->
      with_tmpfile (file) ->
        file\delete!
        assert_error -> file\delete!

  it 'rm_r is an alias for delete_all', ->
    assert_equal File.rm_r, File.delete_all

  describe 'touch', ->
    it 'creates the file if does not exist', ->
      with_tmpfile (file) ->
        file\delete!
        file\touch!
        assert_true file.exists

    it 'raises an error if the file could not be created', ->
      file = File '/no/does/not/exist'
      assert_error -> file\touch!

  describe 'find', ->
    with_populated_dir = (f) ->
      with_tmpdir (dir) ->
        dir\join('child1')\mkdir!
        dir\join('child1/sub_dir')\mkdir!
        dir\join('child1/sub_child.txt')\touch!
        dir\join('child1/sandwich.lua')\touch!
        dir\join('child2')\touch!
        f dir

    it 'raises an error if the file is not a directory', ->
      file = File '/no/does/not/exist'
      assert_error -> file\find!

    context 'with no parameters given', ->
      it 'returns a table with all sub entries', ->
        with_populated_dir (dir) ->
          files = dir\find!
          table.sort files, (a,b) -> a.path < b.path
          normalized = [f\relative_to_parent dir for f in *files]
          assert_table_equal normalized, {
            'child1',
            'child1/sandwich.lua',
            'child1/sub_child.txt',
            'child1/sub_dir',
            'child2'
          }
    context 'when name: is passed as an option', ->
      it 'only returns files whose paths matches the specified value', ->
        with_populated_dir (dir) ->
          files = dir\find name: 'sub_[cd]'
          names = [f.basename for f in *files]
          table.sort names
          assert_table_equal names, { 'sub_child.txt', 'sub_dir' }

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

