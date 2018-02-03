{:File} = howl.io
{:ignore_file} = howl.util

describe 'ignore_file', ->

  assert_matches = (ignore, t) ->
    for reject in *(t.rejected or {})
      assert.is_true ignore(reject), "'#{reject}' should have been rejected, was not"

    for allow in *(t.allowed or {})
      assert.is_false ignore(allow), "'#{allow}' should have been allowed, was not"

  assert_ignores = (content, t) ->
    File.with_tmpfile (f) ->
      f.contents = content
      ignore = ignore_file f
      assert_matches ignore, t

  describe 'matching', ->
    it 'handles plain specifications', ->
      assert_ignores 'foo', {
        rejected: { 'foo', 'foo/', 'sub/foo', 'sub/foo/'}
        allowed: { 'food', 'snafoo', 'sub/food', 'sub/snafoo' }
      }

      assert_ignores 'bar/zed', {
        rejected: { 'bar/zed', 'bar/zed/' }
        allowed: { 'bar/zedi' }
      }

    it 'handles one level shell glob patterns', ->
      assert_ignores [[
          prefix*
          *end
          a*z
          *.o
        ]], {
        rejected: {
          'prefixed',
          'prefix',
          'bend',
          'end',
          'akz',
          'subdir/withend',
          'src/main.o'
        }
        allowed: {
          'prefi',
          'ended',
          'baz',
          'azX'
        }
      }

      assert_ignores '*', {
        rejected: {'all', 'whatever.ext', 'sub/some'}
      }

    it 'handles trailing-separator directory specifications', ->
      assert_ignores [[
          dir/
          sub/dir/
        ]], {
        rejected: { 'dir/', 'sub/dir/' }
        allowed: { 'dir', 'sub' }
      }

    it 'handles single sub dir globs', ->
      assert_ignores [[
          sub/*.o
        ]], {
        rejected: { 'sub/foo.o' }
        allowed: { 'sub/x/foo.o' }
      }

    it 'handles double sub dir globs', ->
      assert_ignores [[
        **/foo
        **/zed/bar
      ]], {
        rejected: {
          'foo',
          'sub/foo',
          'zed/bar',
          'sub/zed/bar',
          'sub1/sub2/zed/bar'
        }
        allowed: { 'sub/food', 'prezed/bar' }
      }

      assert_ignores 'foo/**', {
        rejected: { 'foo/bar', 'foo/bar/zed' }
        allowed: { 'foo/' }
      }

      assert_ignores 'a/**/b', {
        rejected: { 'a/b', 'a/x/b', 'a/x/y/b' }
        allowed: { 'b', 'ab', 'aa/b', 'aa/x/b', 'sub/a/b', 'a/ab' }
      }

    it 'handles specifications with leading slashes', ->
      assert_ignores '/foo', {
        rejected: { 'foo', 'foo/' }
        allowed: { 'food', 'snafoo', 'sub/foo', 'sub/foo/' }
      }

      assert_ignores '/sub/foo', {
        rejected: { 'sub/foo', 'sub/foo/' }
        allowed: { 'foo' }
      }

      assert_ignores '/**/foo', {
        rejected: { 'foo', 'foo/', 'sub/foo', 'sub/sub2/foo' }
        allowed: { 'food' }
      }

    it 'ignores invalid sequential asterisks', ->
      assert_ignores '***', {
        rejected: { '***' }
        allowed: { '**', '****', 'xxx', 'xxxyyy' }
      }

    it 'is not confused by special characters in patterns', ->
      assert_ignores [[
          *.ext
        ]], {
        rejected: { 'foo.ext' }
        allowed: { 'fooext' }
      }

    it 'handles escapes in the patterns', ->
      assert_ignores [[
          \#hash
          \ space
          \!important
        ]], {
        rejected: { '#hash', ' space', '!important' }
        allowed: { 'hash', 'space', 'important' }
      }

    it 'handles negations and match order in the ignore patterns', ->
      assert_ignores [[
          *
          !foo
        ]], {
        rejected: { 'food', ' snafoo', 'whatever' }
        allowed: { 'foo' }
      }

  describe 'ignore file handling', ->
    it 'loads top-level and parent ignore files automatically', ->
      with_tmpdir (dir) ->
        parent_ignore = dir\join('.ignore')
        parent_ignore.contents = 'foo'

        root = dir\join('root')
        root\mkdir_p!
        root_ignore = root\join('.ignore')
        root_ignore.contents = 'bar'

        ignore = ignore_file.evaluator root
        assert.is_true ignore 'bar'
        assert.is_true ignore 'foo'

    it 'defaults to loading ".ignore" and ".gitignore", prefering ".ignore"', ->
      with_tmpdir (dir) ->
        ignore = dir\join('.ignore')
        ignore.contents = [[
          foo
          !bar
        ]]

        gitignore = dir\join('.gitignore')
        gitignore.contents = [[
          bar
          zed
        ]]

        assert_matches ignore_file.evaluator(dir), {
          rejected: { 'foo', 'zed' }
          allowed: { 'bar' }
        }

    it 'allows specifying ignore files with the .ignore_files option', ->
      with_tmpdir (dir) ->
        dir\join('.ignore').contents = '!foo'
        dir\join('.gitignore').contents = 'foo'
        ignore = ignore_file.evaluator dir, ignore_files: {'.gitignore'}
        assert.is_true ignore 'foo'

    it 'matches patterns relative to the ignore file', ->
      with_tmpdir (parent) ->
        root = parent\join('root')
        sub = root\join('sub')
        deep = sub\join('deep')
        deep\mkdir_p!

        parent\join('.ignore').contents = [[
          root/foo
          *.o
        ]]
        root\join('.ignore').contents = 'bar'
        sub\join('.ignore').contents = [[
          below
          deep/frob
        ]]
        deep\join('.ignore').contents = [[
          zed*
          !my.o
        ]]

        assert_matches ignore_file.evaluator(root), {
          rejected: {
            'foo', -- parent file
            'obj.o' -- parent file
            'bar', -- root file
            'sub/below', --sub file
            'sub/deep/frob', -- sub file
            'sub/deep/zeddy', -- deep file
          }
          allowed: {
            'whatever',
            'root/foo',
            'below',
            'root/below',
            'sub/deep/my.o' -- whitelisted by deep file
          }
        }
