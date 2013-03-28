import Matcher from howl.util

describe 'Matcher', ->
  it 'matches if all characters are present', ->
    c = { 'One', 'Green Fields', 'two', 'overflow' }
    m = Matcher c
    assert.same { 'One', 'Green Fields' }, m('ne')

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
    it 'set .how to the type of match', ->
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

