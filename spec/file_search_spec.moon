-- Copyright 2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:file_search} = howl
{:File, :Process} = howl.io

describe 'file_search', ->
  local searchers, tmp_dir, config, searcher

  setup ->
    searchers = file_search.searchers
    for name in pairs searchers
      file_search.unregister_searcher name

    tmp_dir = File.tmpdir!
    config = howl.config.for_file tmp_dir

  teardown ->
    for name in pairs file_search.searchers
      file_search.unregister_searcher name

    for _, def in pairs searchers
      file_search.register def

    tmp_dir\delete_all!

  before_each ->
    searcher = {
      name: 'test'
      description: 'test'
      handler: -> {}
    }

  describe 'register_searcher(def)', ->
    it 'raises an error for missing attributes', ->
      assert.raises "name", ->
        file_search.register_searcher description: 'desc', handler: ->

      assert.raises "description", ->
        file_search.register_searcher name: 'name', handler: ->

      assert.raises "handler", ->
        file_search.register_searcher name: 'test', description: 'desc'

  describe 'search(directory, term)', ->
    context '(when the searcher returns matches directly)', ->
      before_each ->
        file_search.register_searcher searcher
        config.file_searcher = 'test'

      it 'returns matches from the specified searcher', ->
        matches = {
          { path: 'urk.txt', file: tmp_dir\join('urk'), line_nr: 1, message: 'foo'}
        }
        searcher.handler = -> matches
        res = file_search.search tmp_dir, 'foo'
        assert.same matches, res

      it 'raises an error if the searcher omits required match fields', ->
        matches = {}
        searcher.handler = -> matches

        matches[1] = { line_nr: 1, message: 'foo' }
        assert.raises 'path', -> file_search.search tmp_dir, 'foo'

        matches[1] = { path: 'urk.txt', message: 'foo' }
        assert.raises 'line_nr', -> file_search.search tmp_dir, 'foo'

        matches[1] = { path: 'urk.txt', line_nr: 1 }
        assert.raises 'message', -> file_search.search tmp_dir, 'foo'

      it 'sets .file from path if not provided', ->
        searcher.handler = -> { { path: 'urk.txt', line_nr: 1, message: 'foo'} }
        res = file_search.search tmp_dir, 'foo'
        assert.equal tmp_dir\join('urk.txt'), res[1].file

    context '(when the searcher returns a process object)', ->
      it "returns matches from the process' output", (done) ->
        file_search.register_searcher searcher
        config.file_searcher = 'test'

        howl_async ->
          searcher.handler = -> Process.open_pipe 'echo "file.ext:10: foo"'
          res = file_search.search tmp_dir, 'foo'
          assert.same {
            {message: 'foo', path: 'file.ext', line_nr: 10, file: tmp_dir\join('file.ext')}
          }, res
          done!

    context '(when the searcher returns a string)', ->
      it 'returns matches from running the string as a command', (done) ->
        file_search.register_searcher searcher
        config.file_searcher = 'test'

        howl_async ->
          searcher.handler = -> 'echo "file.ext:10: foo"'
          res = file_search.search tmp_dir, 'foo'
          assert.same {
            {message: 'foo', path: 'file.ext', line_nr: 10, file: tmp_dir\join('file.ext')}
          }, res
          done!

    context '(selecting the searcher)', ->
      it 'raises an error if the specified searcher is not available', ->
        searcher.is_available = -> false
        file_search.register_searcher searcher
        config.file_searcher = 'test'
        assert.raises 'unavailable', -> file_search.search tmp_dir, 'foo'

  describe 'sort(matches, context)', ->
    match = (message, path, line_nr = 1) ->
      {:message, :path, :line_nr, file: tmp_dir\join(path)}

    messages = (matches) -> [m.message for m in *matches]

    it 'prefers standalone matches to substring matches', ->
      sorted = file_search.sort {
        match('a fool', 'sub1')
        match('bar foo zed', 'alone')
        match('food for thought', 'sub2')
      }, tmp_dir, 'foo'
      assert.equal 'alone', sorted[1].path

    it "prefers matches where the term is included in the match's base name", ->
      sorted = file_search.sort {
        match('notbase', 'foo/zed.moon')
        match('base', 'bar/foo.moon')
      }, tmp_dir, 'foo'
      assert.same {'base', 'notbase'}, messages(sorted)

    it 'penalizes matches in test files', ->
      sorted = file_search.sort {
        match('spec', 'foo/zed_spec.moon')
        match('test', 'foo/zed_test.moon')
        match('specd', 'foo/zed-spec.moon')
        match('testd', 'foo/zed-test.moon')
        match('testp', 'foo/test_test.moon')
        match('base', 'foo/zed.moon')
      }, tmp_dir, 'foo'
      assert.same 'base', messages(sorted)[1]

    it 'groups matches by path for same-score matches', ->
      sorted = file_search.sort {
        match('foo', 'one.moon')
        match('foo', 'two.moon')
        match('bar', 'one.moon')
        match('bar', 'two.moon')
      }, tmp_dir, 'xxx'
      assert.equal sorted[1].path, sorted[2].path
      -- and it follows that 3 4 are equal

    context 'when context is provided', ->
      local buffer

      before_each ->
        buffer = howl.Buffer!

      it 'prefers matches close to the current context directory', ->
        buffer.file = tmp_dir\join 'first/second/file.txt'
        sorted = file_search.sort {
          match('twoup', 'twoup.txt') -- distance 3
          match('samedir', 'first/second/samedir.txt') -- distance 1
          match('same', 'first/second/file.txt') -- distance 0
          match('oneup', 'first/oneup.txt') -- distance 2
          match('diffroot', 'other/otro/annan.txt') --distance 5
        }, tmp_dir, 'foo', buffer\context_at(1)

        assert.same {'same', 'samedir', 'oneup', 'twoup', 'diffroot'}, messages(sorted)

      it 'prefers matches in files sharing the same name cluster', ->
        buffer.file = tmp_dir\join 'foo.moon'
        sorted = file_search.sort {
          match('notsame', 'food.moon')
          match('spec', 'foo_spec.moon')
          match('other', 'angry/fools.moon')
        }, tmp_dir, 'foo', buffer\context_at(1)

        assert.same {'spec', 'notsame', 'other'}, messages(sorted)

        buffer.file = tmp_dir\join 'foo_spec.moon'
        sorted = file_search.sort {
          match('notsame', 'food.moon')
          match('main', 'foo.moon')
          match('other', 'angry/fools.moon')
        }, tmp_dir, 'search', buffer\context_at(1)

        assert.same {'main', 'notsame', 'other'}, messages(sorted)
