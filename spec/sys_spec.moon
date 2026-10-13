sys = howl.sys

describe 'sys', ->
  describe '.env', ->
    env = sys.env

    it 'allows reading environment variables using plain indexing', ->
      assert.equals 'string', type env.HOME
      assert.equals 'string', type env['HOME']
      assert.equals os.getenv('HOME'), env.HOME

    it 'allows setting variables via assignment', ->
      env.MY_VAR = 'myval'
      assert.equals 'myval', env.MY_VAR
      assert.equals 'myval', os.getenv('MY_VAR')

    it 'allows unsetting variables using a nil assignment', ->
      env.MY_VAR = 'myval'
      assert.equals 'myval', os.getenv('MY_VAR')
      env.MY_VAR = nil
      assert.is_nil env.MY_VAR
      assert.is_nil os.getenv('MY_VAR')

    it 'allows iterating over the env using pairs', ->
      env.MY_VAR = 'yowser!'
      as_table = {k,v for k,v in pairs env}
      assert.equals 'yowser!', as_table.MY_VAR

  describe 'find_executable(name, path)', ->
    it "returns the path of the executable found in Howl's PATH by default", ->
      found = sys.find_executable 'sh'
      assert.is_not_nil found
      assert.equals 'sh', howl.io.File(found).basename

    it 'returns nil when the executable is not found', ->
      assert.is_nil sys.find_executable 'howl-no-such-executable'

    it 'looks only in path when given', ->
      with_tmpdir (dir) ->
        (dir / 'howl-tool').contents = ''
        assert.equals (dir / 'howl-tool').path, sys.find_executable 'howl-tool', "/howl-none:#{dir.path}"
        assert.is_nil sys.find_executable 'howl-tool'
        assert.is_nil sys.find_executable 'sh', dir.path

  describe '.info', ->
    it '.os is the lower case OS name', ->
      assert.equals jit.os\lower!, sys.info.os
