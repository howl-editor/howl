import inputs, Project from howl
import File from howl.fs

require 'howl.inputs.projectfile_input'

describe 'ProjectFile', ->

  it 'registers a "project_file" input', ->
    assert.not_nil inputs.project_file

  describe 'when a file and project is available', ->
    root = nil
    input = nil
    file = nil

    before_each ->
      root = File.tmpdir!
      root\join('subdir')\mkdir!
      root\join('subdir/foo')\touch!
      root\join('simple.txt')\touch!
      file = root\join('Makefile')
      file\touch!

      _G.editor = buffer: :file
      Project.add_root root
      input = inputs.project_file!

    after_each ->
      Project.remove_root root
      root\delete_all!

    it '.should_complete() returns true', ->
      assert.is_true input\should_complete!

    it '.complete() returns a sorted list of relative paths', ->
      comps = input\complete ''
      assert.same comps, {
        'Makefile',
        'simple.txt',
        'subdir/',
        'subdir/foo'
      }

    it '.value_for(path) returns a File', ->
      assert.equal input\value_for('Makefile'), file

  describe 'when a file is available but not a project', ->
    input = nil
    file = nil

    before_each ->
      file = File.tmpfile!
      _G.editor = buffer: :file
      input = inputs.project_file!

    after_each -> file\delete!

    it '.complete() returns an empty table', ->
      assert.same input\complete(''), {}

    it '.value_for(path) returns nil', ->
      assert.is_nil input\value_for 'foo'

  describe 'when file is not available', ->
    before_each -> _G.editor = buffer: {}

    it '.complete() returns an empty table', ->
      assert.same inputs.project_file!\complete(''), {}

    it '.value_for(path) returns nil', ->
      assert.is_nil inputs.project_file!\value_for 'foo'
