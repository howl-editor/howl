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
      readline = prompt: 'open ', text: ''
      directory = File.tmpdir!
      _G.editor = buffer: file: parent: directory
      input = inputs.file readline

    after_each ->
      directory\rm_r!
      _G.editor = nil

    it 'should_complete() returns true', ->
      assert.is_true input\should_complete!

    describe 'complete(text, readline)', ->
      it 'returns files matching <text>', ->
        directory\join('test.lua')\touch!
        directory\join('foo.lua')\touch!

        readline.text = 'foo'
        files = input\complete 'foo', readline
        assert.same { 'foo.lua' }, files

      it 'automatically switches to root dir if the text is "/"', ->
        input\complete '', readline
        readline.text ..= '/'
        input\complete readline.text, readline
        assert.equals 'open /', readline.prompt

      it 'automatically switches to the #home dir if the text is "~/"', ->
        input\complete '', readline
        readline.text ..= '~/'
        input\complete readline.text, readline
        assert.equals "open #{os.getenv('HOME')}/", readline.prompt

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
