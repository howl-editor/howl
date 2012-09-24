import Spy from lunar.spec
import config from lunar

describe 'log', ->
  after ->
    log.clear!
    _G.window = nil

  it 'is exported globally as `log`', ->
    assert_equal type(_G.log), 'table'

  for m in *{'info', 'warning', 'error'}
    describe m .. '(text)', ->
      it 'propages the message to _G.window.status\\' .. m .. '() if available', ->
        _G.window = status: [m]: Spy!
        log[m] 'message'
        parameters = _G.window.status[m].called_with
        assert_equal parameters[1], _G.window.status
        assert_equal parameters[2], 'message'

  describe 'book keeping', ->
    it '.entries is a list of the last log entries', ->
      log.error 'my error'
      assert_equal #log.entries, 1
      assert_table_equal log.entries[1], {
        message: 'my error'
        level: 'error'
      }

    it 'defines a "max_log_entries" config variable, defaulting to 1000', ->
      assert_not_nil config.definitions.max_log_entries
      assert_equal config.max_log_entries, 1000

    it 'retains at most <max_log_entries> of the last entries', ->
      config.max_log_entries = 1
      for i = 1,10
        log.error 'my error ' .. i

      assert_equal #log.entries, 1
      assert_table_equal log.entries[1], {
        message: 'my error 10'
        level: 'error'
      }

    it '.clear() clears all log entries', ->
      log.error 'my error'
      log.clear!
      assert_equal #log.entries, 0
