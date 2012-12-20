import inputs from howl
import File from howl.fs

require 'howl.inputs.file_input'

describe 'FileInput', ->

  it 'registers a "file" input', ->
    assert.not_nil inputs.file

  describe 'an instance', ->
    local directory, input, files, readline

    before_each ->
      files = {}
      readline = prompt: 'prompt', text: 'text'
      directory = File.tmpdir!
      _G.editor = buffer: file: parent: directory
      input = inputs.file!

    after_each ->
      directory\rm_r!
      _G.editor = nil

    it 'should_complete() returns true', ->
      assert.is_true input\should_complete!

    it 'complete(text, readline) returns files matching <text>', ->
      directory\join('test.lua')\touch!
      directory\join('foo.lua')\touch!

      files = input\complete 'foo', readline
      assert.same { 'foo.lua' }, files

    it 'on_completed(path, readline) changes dir and returns false for sub dir', ->
      sub = directory\join('sub')
      sub\mkdir!
      sub\join('subfile.txt')\touch!
      assert.is_false input\on_completed 'sub', readline
      readline.text = 'sub'
      files = input\complete 'sub', readline
      assert.same { 'subfile.txt' }, files

    it 'value_for(text) returns a File for <text>', ->
      file = directory\join('test.lua')
      file\touch!
      assert.equal file, input\value_for 'test.lua'

    it 'go_back(readline) goes up a directory', ->
      input\go_back readline
      assert.equal directory, input\value_for directory.basename
