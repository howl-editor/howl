import config from howl

describe 'log', ->
  after_each ->
    log.clear!
    _G.window = nil

  it 'is exported globally as `log`', ->
    assert.equal type(_G.log), 'table'

  for m in *{'info', 'warning', 'error'}
    describe m .. '(text)', ->
      it 'propages the message to _G.window.status\\' .. m .. '() if available', ->
        method = spy.new -> true
        _G.window = readline: {}, status: [m]: method
        log[m] 'message'
        assert.spy(method).was.called_with _G.window.status, 'message'

      it 'only propagates the first line of the message', ->
        method = spy.new -> true
        _G.window = readline: {}, status: [m]: method
        log[m] 'message\nline2\nline3'
        assert.spy(method).was.called_with _G.window.status, 'message'

  describe 'book keeping', ->
    it '.entries is a list of the last log entries', ->
      log.error 'my error'
      assert.equal #log.entries, 1
      assert.same log.entries[1], {
        message: 'my error'
        level: 'error'
      }

    it '.last_error points to the last error logged', ->
      assert.is_nil log.last_error
      log.error 'foo'
      assert.equal 'foo', log.last_error.message
      log.error 'bar'
      assert.equal 'bar', log.last_error.message

    it 'defines a "max_log_entries" config variable, defaulting to 1000', ->
      assert.not_nil config.definitions.max_log_entries
      assert.equal config.max_log_entries, 1000

    it 'retains at most <max_log_entries> of the last entries', ->
      config.max_log_entries = 1
      for i = 1,10
        log.error 'my error ' .. i

      assert.equal #log.entries, 1
      assert.same log.entries[1], {
        message: 'my error 10'
        level: 'error'
      }

    it '.clear() clears all log entries', ->
      log.error 'my error'
      log.clear!
      assert.equal #log.entries, 0
