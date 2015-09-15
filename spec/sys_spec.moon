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

  describe '.info', ->
    it '.os is the lower case OS name', ->
      assert.equals jit.os\lower!, sys.info.os
