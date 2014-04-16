import File from howl.io

describe 'File', ->

  describe 'tmpfile()', ->
    it 'returns a file instance pointing to an existing file', ->
      file = File.tmpfile!
      assert.is_true file.exists
      file\delete!

  describe 'with_tmpfile(f)', ->
    it 'invokes <f> with the file', ->
      f = spy.new (file) ->
        assert.equals 'File', typeof(file)

      File.with_tmpfile f
      assert.spy(f).was_called(1)

    it 'removes the temporary file even if <f> raises an error', ->
      local tmpfile
      f = (file) ->
        tmpfile = file
        error 'noo'

      assert.raises 'noo', -> File.with_tmpfile f
      assert.is_false tmpfile.exists

  describe 'tmpdir()', ->
    it 'returns a file instance pointing to an existing directory', ->
      file = File.tmpdir!
      assert.is_true file.exists
      assert.is_true file.is_directory
      file\delete_all!

  describe 'expand_path(path)', ->
    it 'expands "~" into the full path of the home directory', ->
      assert.equals "#{os.getenv('HOME')}/foo.txt", (File.expand_path '~/foo.txt')

  describe 'new(...)', ->
    it 'accepts a string as denothing a path', ->
      File '/bin/ls'

    it 'accepts other files as well', ->
      f = File '/bin/ls'
      f2 = File f
      assert.equal f, f2

  describe '.is_absolute', ->
    it 'returns true if the given path is absolute', ->
      assert.is_true File.is_absolute '/bin/ls'
      assert.is_true File.is_absolute 'c:\\\\bin\\ls'

    it 'returns false if the given path is absolute', ->
      assert.is_false File.is_absolute 'bin/ls'
      assert.is_false File.is_absolute 'bin\\ls'

  it '.basename returns the basename of the path', ->
    assert.equal File('/foo/base.ext').basename, 'base.ext'

  it '.extension returns the extension of the path', ->
    assert.equal File('/foo/base.ext').extension, 'ext'

  it '.path returns the path of the file', ->
    assert.equal '/foo/base.ext', File('/foo/base.ext').path

  it '.uri returns an URI representing the path', ->
    assert.equal File('/foo.txt').uri, 'file:///foo.txt'

  it '.exists returns true if the path exists', ->
    File.with_tmpfile (file) -> assert.is_true file.exists

  describe '.short_path', ->
    it 'returns the path with the home directory replace by "~"', ->
      file = File(os.getenv('HOME')) / 'foo.txt'
      assert.equal '~/foo.txt', file.short_path

  describe 'contents', ->
    it 'assigning a string writes the string to the file', ->
      File.with_tmpfile (file) ->
        file.contents = 'hello world'
        f = io.open file.path
        read_back = f\read '*all'
        f\close!
        assert.equal read_back, 'hello world'

    it 'returns the contents of the file', ->
      File.with_tmpfile (file) ->
        f = io.open file.path, 'w'
        f\write 'hello world'
        f\close!
        assert.equal file.contents, 'hello world'

  it '.parent return the parent of the file', ->
    assert.equal File('/bin/ls').parent.path, '/bin'

  it '.children returns a table of children', ->
    with_tmpdir (dir) ->
      dir\join('child1')\mkdir!
      dir\join('child2')\touch!
      kids = dir.children
      table.sort kids, (a,b) -> a.path < b.path
      assert.same [v.basename for v in *kids], { 'child1', 'child2' }

  it '.file_type is a string describing the file type', ->
    assert.equal 'directory', File('/bin').file_type
    assert.equal 'regular', File('/bin/ls').file_type
    assert.equal 'special', File('/dev/null').file_type

  it '.writeable is true if the file represents a entry that can be written to', ->
    with_tmpdir (dir) ->
      assert.is_true dir.writeable
      file = dir / 'file.txt'
      assert.is_true file.writeable
      file\touch!
      assert.is_true file.writeable

    assert.is_false File('/no/such/directory/orfile.txt').writeable

  it '.readable is true if the file represents a entry that can be read', ->
    with_tmpdir (dir) ->
      assert.is_true dir.readable
      file = dir / 'file.txt'
      assert.is_false file.readable
      file\touch!
      assert.is_true file.readable

  it '.etag is a string that can be used to check for modification', ->
    File.with_tmpfile (file) ->
      assert.is.not_nil file.etag
      assert.equal type(file.etag), 'string'

  it '.modified_at is a the unix time when the file was last modified', ->
    File.with_tmpfile (file) ->
      assert.is.not_nil file.modified_at

  describe 'open([mode, function])', ->
    context 'when <function> is nil', ->
      it 'returns a Lua file handle', ->
        File.with_tmpfile (file) ->
          file.contents = 'first line\nsecond line\n'
          fh = file\open!
          assert.equal 'first line', fh\read!
          assert.equal 'second line\n', fh\read '*L'
          fh\close!

    context 'when <function> is provided', ->
      it 'it is invoked with the file handle', ->
        File.with_tmpfile (file) ->
          file.contents = 'first line\nsecond line\n'
          local first_line
          file\open 'r', (fh) ->
            first_line = fh\read!

          assert.equal 'first line', first_line

      it 'returns the returns values of the function', ->
        File.with_tmpfile (file) ->
          assert.same { 'callback', nil, 'last' }, { file\open 'r', -> 'callback', nil, 'last' }

      it 'closes the file automatically after invoking <function>', ->
        File.with_tmpfile (file) ->
          local handle
          file\open 'r', (fh) -> handle = fh
          assert.has_errors -> handle\read!

      context 'when <function> raises an error', ->
        it 'propagates that error', ->
          File.with_tmpfile (file) ->
            assert.raises 'kaboom', -> file\open 'r', -> error 'kaboom'

        it 'still closes the file', ->
          File.with_tmpfile (file) ->
            local handle
            pcall -> file\open 'r', (fh) ->
              handle = fh
              error 'kaboom'

            assert.has_errors -> handle\read!

  it 'read(..) is a short hand for doing a read(..) on the Lua file handle', ->
    File.with_tmpfile (file) ->
      file.contents = 'first line\n'
      assert.same { 'first', ' line' }, { file\read 5, '*l' }

  it 'join() returns a new file representing the specified child', ->
    assert.equal File('/bin')\join('ls').path, '/bin/ls'

  it 'relative_to_parent() returns a path relative to the specified parent', ->
    parent = File '/bin'
    file = File '/bin/ls'
    assert.equal 'ls', file\relative_to_parent(parent)

  it 'is_below(dir) returns true if the file is located beneath <dir>', ->
    parent = File '/bin'
    assert.is_true File('/bin/ls')\is_below parent
    assert.is_true File('/bin/sub/ls')\is_below parent
    assert.is_false File('/usr/bin/ls')\is_below parent

  describe 'mkdir()', ->
    it 'creates a directory for the path specified by the file', ->
      File.with_tmpfile (file) ->
        file\delete!
        file\mkdir!
        assert.is_true file.exists and file.is_directory

    it 'raises an error if the directory could not be created', ->
      assert.has_error -> File('/aksdjskjdgudfkj')\mkdir!

  describe 'mkdir_p()', ->
    it 'creates a directory for the path specified by the file, including parents', ->
      File.with_tmpfile (file) ->
        file\delete!
        file = file\join 'sub/foo'
        file\mkdir_p!
        assert.is_true file.exists and file.is_directory

  describe 'delete()', ->
    it 'deletes the target file', ->
      File.with_tmpfile (file) ->
        file\delete!
        assert.is_false file.exists

    it 'raise an error if the file does not exist', ->
      file = File.tmpfile!
      file\delete!
      assert.error -> file\delete!

  it 'rm and unlink is an alias for delete', ->
    assert.equal File.rm, File.delete
    assert.equal File.unlink, File.delete

  describe 'delete_all()', ->
    context 'for a regular file', ->
      it 'deletes the target file', ->
        File.with_tmpfile (file) ->
          file\delete_all!
          assert.is_false file.exists

    context 'for a directory', ->
      it 'deletes the directory and all sub entries', ->
        with_tmpdir (dir) ->
          dir\join('child1')\mkdir!
          dir\join('child1/sub_child')\touch!
          dir\join('child2')\touch!
          dir\delete_all!
          assert.is_false dir.exists

    it 'raise an error if the file does not exist', ->
      File.with_tmpfile (file) ->
        file\delete!
        assert.error -> file\delete!

  it 'rm_r is an alias for delete_all', ->
    assert.equal File.rm_r, File.delete_all

  describe 'touch()', ->
    it 'creates the file if does not exist', ->
      File.with_tmpfile (file) ->
        file\delete!
        file\touch!
        assert.is_true file.exists

    it 'raises an error if the file could not be created', ->
      file = File '/no/does/not/exist'
      assert.error -> file\touch!

  describe 'tostring()', ->
    it 'returns a string containing the path', ->
      File.with_tmpfile (file) ->
        to_s = file\tostring!
        assert.equal 'string', typeof to_s
        assert.equal to_s, file.path

  describe 'find()', ->
    with_populated_dir = (f) ->
      with_tmpdir (dir) ->
        dir\join('child1')\mkdir!
        dir\join('child1/sub_dir')\mkdir!
        dir\join('child1/sub_dir/deep.lua')\touch!
        dir\join('child1/sub_child.txt')\touch!
        dir\join('child1/sandwich.lua')\touch!
        dir\join('child2')\touch!
        f dir

    it 'raises an error if the file is not a directory', ->
      file = File '/no/does/not/exist'
      assert.error -> file\find!

    context 'with no parameters given', ->
      it 'returns a list of all sub entries', ->
        with_populated_dir (dir) ->
          files = dir\find!
          table.sort files, (a,b) -> a.path < b.path
          normalized = [f\relative_to_parent dir for f in *files]
          assert.same {
            'child1',
            'child1/sandwich.lua',
            'child1/sub_child.txt',
            'child1/sub_dir',
            'child1/sub_dir/deep.lua',
            'child2'
          }, normalized

    context 'when the sort parameter is given', ->
      it 'returns a list of all sub entries in a pleasing order', ->
        with_populated_dir (dir) ->
          files = dir\find sort: true
          normalized = [f\relative_to_parent dir for f in *files]
          assert.same normalized, {
            'child2',
            'child1',
            'child1/sandwich.lua',
            'child1/sub_child.txt',
            'child1/sub_dir',
            'child1/sub_dir/deep.lua',
          }

    context 'when filter: is passed as an option', ->
      it 'excludes files for which <filter(file)> returns true', ->
        with_populated_dir (dir) ->
          files = dir\find filter: (file) ->
            file.basename != 'sandwich.lua' and file.basename != 'child1'

          assert.same { 'child1', 'sandwich.lua' }, [f.basename for f in *files]

  describe 'meta methods', ->
    it '/ and .. joins the file with the specified argument', ->
      file = File('/bin')
      assert.equal (file / 'ls').path, '/bin/ls'
      assert.equal (file .. 'ls').path, '/bin/ls'

    it 'tostring returns the result of File.tostring', ->
      file = File '/bin/ls'
      assert.equal file\tostring!, tostring file

    it '== returns true if the files point to the same path', ->
      assert.equal File('/bin/ls'), File('/bin/ls')

