import app, inputs from howl
import File from howl.fs

require 'howl.inputs.file_input'

describe 'File inputs', ->
  local directory, files, readline

  before_each ->
    files = {}
    readline = prompt: 'open ', text: ''
    directory = File.tmpdir!
    app.editor = buffer: file: parent: directory

  after_each ->
    directory\rm_r!
    app.editor = nil

  for input_type in *{'File', 'Directory'}
    name = input_type.ulower

    describe "#{input_type}Input", ->

      it "registers a '#{name}' input", ->
        assert.not_nil inputs[name]

      describe 'an instance', ->
        local input

        before_each -> input = inputs[name] readline

        it 'should_complete() returns true', ->
          assert.is_true input\should_complete!

        describe 'complete(text, readline)', ->
          it 'automatically switches to root dir if the text is "/"', ->
            input\complete '', readline
            readline.text ..= '/'
            input\complete readline.text, readline
            assert.equals 'open /', readline.prompt

          it 'automatically switches to the home dir if the text is "~/"', ->
            input\complete '', readline
            readline.text ..= '~/'
            input\complete readline.text, readline
            assert.equals "open #{os.getenv('HOME')}/", readline.prompt

          it 'automatically opens directory if text has trailing "/"', ->
            sub = directory\join('sub')
            sub\mkdir!
            readline.text ..= 'sub/'
            input\complete readline.text, readline
            assert.equals "open #{sub.path}/", readline.prompt

        describe 'on_completed(path, readline)', ->
          it 'changes dir and returns false when <path> is a directory', ->
            sub = directory\join('sub')
            sub\mkdir!
            sub\join('subdir')\mkdir!
            assert.is_false input\on_completed 'sub', readline
            readline.text = 'sub'
            files = input\complete 'sub', readline
            assert.same { 'subdir/' }, files

        it 'value_for(text) returns a File for <text>', ->
          file = directory\join('test.lua')
          file\touch!
          assert.equal file, input\value_for 'test.lua'

        it 'go_back(readline) goes up a directory', ->
          input\go_back readline
          assert.equal directory, input\value_for directory.basename

  describe 'FileInput', ->
    describe 'complete(text, readline)', ->
      it 'returns all files matching <text>', ->
        input = inputs.file readline
        directory\join('test.lua')\touch!
        directory\join('foo.lua')\touch!
        directory\join('foodir')\mkdir!

        readline.text = 'foo'
        files = input\complete 'foo', readline
        assert.same { 'foodir/', 'foo.lua' }, files

  describe 'DirectoryInput', ->
    local input
    before_each -> input = inputs.directory readline

    describe 'complete(text, readline)', ->
      it 'returns all directories matching <text>', ->
        directory\join('foo.lua')\touch!
        directory\join('foodir')\mkdir!
        directory\join('bardir')\mkdir!

        readline.text = 'foo'
        files = input\complete 'foo', readline
        assert.same { 'foodir/' }, files

      it 'always includes the current directory as well', ->
        readline.text = ''
        files = input\complete '', readline
        assert.same { './' }, files

    describe 'on_completed(path, readline)', ->
      it 'returns non-false when the current directory is choosen', ->
        assert.is_not_false input\on_completed './', readline
