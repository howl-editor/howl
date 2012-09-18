import inputs, Project from lunar
import File from lunar.fs

require 'lunar.inputs.projectfile'

describe 'ProjectFile', ->

  it 'registers a "project_file" input', ->
    assert_not_nil inputs.project_file

  describe 'when a file and project is available', ->
    root = nil
    input = nil
    file = nil

    before ->
      root = File.tmpdir!
      root\join('subdir')\mkdir!
      root\join('subdir/foo')\touch!
      root\join('simple.txt')\touch!
      file = root\join('Makefile')
      file\touch!

      _G.editor = buffer: :file
      Project.add_root root
      input = inputs.project_file!

    after -> root\delete_all!

    it '.should_complete() returns true', ->
      assert_true input\should_complete!

    it '.complete() returns a sorted list of relative paths', ->
      comps = input\complete ''
      assert_table_equal comps, {
        'Makefile',
        'simple.txt',
        'subdir/',
        'subdir/foo'
      }

    it '.value_for(path) returns a File', ->
      assert_equal input\value_for('Makefile'), file

  describe 'when a file is available but not a project', ->
    input = nil
    file = nil

    before ->
      file = File.tmpfile!
      _G.editor = buffer: :file
      input = inputs.project_file!

    after -> file\delete!

    it '.complete() returns an empty table', ->
      assert_table_equal input\complete(''), {}

    it '.value_for(path) returns nil', ->
      assert_nil input\value_for 'foo'

  describe 'when file is not available', ->
    before -> _G.editor = buffer: {}

    it '.complete() returns an empty table', ->
      assert_table_equal inputs.project_file!\complete(''), {}

    it '.value_for(path) returns nil', ->
      assert_nil inputs.project_file!\value_for 'foo'
