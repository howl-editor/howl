import Matcher from howl.util

describe 'Matcher(candidates)', ->
  it 'matches if all characters are present', ->
    c = { 'One', 'Green Fields', 'two', 'overflow' }
    m = Matcher c
    assert.same { 'One', 'Green Fields' }, m('ne')

  it 'candidates are automatically converted to strings', ->
    candidate = setmetatable {}, __tostring: -> 'auto'
    m = Matcher { candidate }
    assert.same { candidate }, m('auto')

  it 'candidates can be multi-valued tables', ->
    c = { { 'One', 'Uno' } }
    m = Matcher c
    assert.same { c[1] }, m('One')

  it 'multi-valued candidates are automatically converted to strings', ->
    candidate = setmetatable {}, __tostring: -> 'auto'
    m = Matcher { { candidate, 'desc' } }
    assert.same { { candidate, 'desc' } }, m('auto')

  it 'prefers boundary matches over straight ones over fuzzy ones', ->
    c = { 'kiss her', 'some/stuff/here', 'openssh', 'sss hhh' }
    m = Matcher c
    assert.same {
      'sss hhh',
      'some/stuff/here'
      'openssh',
      'kiss her'
    }, m('ssh')

  it 'prefers early occurring matches over ones at the end', ->
    c = { 'Two items to bind them tight', 'One item to match them' }
    m = Matcher c
    assert.same {
      'One item to match them',
      'Two items to bind them tight'
    }, m('ni')

  it 'prefers shorter matching candidates over longer ones', ->
    c = { 'src/tools.sh', 'TODO' }
    m = Matcher c
    assert.same {
      'TODO',
      'src/tools.sh'
    }, m('to')

  it 'prefers tighter matches to longer ones', ->
    c = { 'aa bb cc dd', 'zzzzzzzzzzzzzzz ad' }

    m = Matcher c
    assert.same {
      'zzzzzzzzzzzzzzz ad',
      'aa bb cc dd',
    }, m('ad')

  it '"special" characters are matched as is', ->
    c = { 'Item 2. 1%w', 'Item 22 2a' }
    m = Matcher c
    assert.same { 'Item 2. 1%w' }, m('%w')

  it 'accepts ustring both for candidates and searches', ->
    c = { 'one', 'two' }
    m = Matcher c
    assert.same { 'one', 'two' }, m('o')

  describe 'explain(search, text)', ->
    it 'sets .how to the type of match', ->
      assert.equal 'exact', Matcher.explain('fu', 'snafu').how

    it 'returns a list of character offsets indicating where <search> matched', ->
      assert.same { how: 'exact', 4, 5, 6 }, Matcher.explain 'ƒlu', 'sñaƒlux'
      assert.same { how: 'fuzzy', 2, 4, 6 }, Matcher.explain 'hiʈ', 'Čhriʂʈmas'
      assert.same { how: 'boundary', 1, 4, 9, 10 }, Matcher.explain 'itʂo', 'iʂ that ʂo'

    it 'lower-cases the search and text just as for matching', ->
      assert.not_nil Matcher.explain 'FU', 'ʂnafu'
      assert.not_nil Matcher.explain 'fu', 'SNAFU'

    it 'accepts ustring both for <search> and <text>', ->
      assert.not_nil Matcher.explain 'FU', 'snafu'

  it 'boundary matches can not skip separators', ->
    assert.equal 'boundary', Matcher.explain('sk', 'nih/says/knights').how
    assert.not_equal 'boundary', Matcher.explain('nk', 'nih/says/knights').how

  describe 'with reverse matching (reverse = true specified as an option)', ->
    it 'prefers late occurring matches over ones at the end', ->
      c = { 'match me', 'me match' }
      m = Matcher c, reverse: true
      assert.same {
        'me match'
        'match me',
      }, m('mat')

    it 'still prefers tighter matches to longer ones', ->
      c = { 'aabbac', 'abbaca' }

      m = Matcher c, reverse: true
      assert.same {
        'aabbac',
        'abbaca',
      }, m('aa')

    it 'still prefers boundary matches over straight ones over fuzzy ones', ->
      c = { 'just kiss her', 'some/stuff/here', 'sshopen', 'open/ssh', 'ss xh' }
      m = Matcher c, reverse: true

      assert.same {
        'open/ssh',
        'sshopen',
        'some/stuff/here'
        'ss xh',
        'just kiss her'
      }, m('ssh')

    it 'explain(search, text) works correctly', ->
      assert.same { how: 'exact', 7, 8, 9 }, Matcher.explain 'aƒl', 'ƒluxsñaƒlux', reverse: true
      assert.same { how: 'boundary', 1, 5 }, Matcher.explain 'as', 'app_spec.fu', reverse: true
      assert.same { how: 'fuzzy', 5, 8 }, Matcher.explain 'sc', 'app_spec.fu', reverse: true
