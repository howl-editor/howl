import Spy from lunar.spec

describe 'log', ->
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

