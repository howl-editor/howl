import Matcher from howl.util

describe 'Matcher', ->

  it 'matches if the search matches exactly', ->
    c = { 'One', 'Green Fields', 'two' }
    m = Matcher c
    assert.same { 'One' }, m('ne')

  describe '(boundary matches)', ->

    it 'matches if the search matches at boundaries', ->
      m = Matcher { 'green fields', 'green sfinx' }
      assert.same { 'green fields' }, m('gf')
      assert.same { 'apaass_so' }, Matcher({'apaass_so'})('as')

    it 'matches if the search matches at upper case boundaries', ->
      m = Matcher { 'camelCase', 'a CreditCard', 'chacha' }
      assert.same { 'camelCase', 'a CreditCard' }, m('cc')

    it 'allows for multiple-character boundaries', ->
      m = Matcher { 'green/_fields', 'green sfinx' }
      assert.same { 'green/_fields' }, m('gf')

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

  it 'prefers boundary matches over exact ones', ->
    c = { 'kiss her', 'some/stuff/here', 'openssh', 'sss hhh' }
    m = Matcher c
    assert.same {
      'sss hhh',
      'some/stuff/here'
      'openssh',
    }, m('ssh')

  it 'prefers early occurring matches over ones at the end', ->
    c = { 'Discard all apples', 'all aardvarks' }
    m = Matcher c
    assert.same {
      'all aardvarks',
      'Discard all apples'
    }, m('aa')

  it 'prefers shorter matching candidates over longer ones', ->
    c = { 'x/tools.sh', 'x/torx' }
    m = Matcher c
    assert.same {
      'x/torx',
      'x/tools.sh'
    }, m('to')

  it 'prefers tighter matches to longer ones', ->
    c = { 'awesome_apples', 'an_aardvark'  }

    m = Matcher c
    assert.same {
      'an_aardvark',
      'awesome_apples',
    }, m('aa')

  it '"special" characters are matched as is', ->
    c = { 'Item 2. 1%w', 'Item 22 2a' }
    m = Matcher c
    assert.same { 'Item 2. 1%w' }, m('%w')
    assert.same { }, m('.*')

  it 'boundary matches can not skip separators', ->
    m = Matcher { 'nih/says/knights' }
    assert.same { 'nih/says/knights' }, m('sk')
    assert.same {}, m('nk')

  it 'accepts ustring both for <search> and <text>', ->
    assert.not_nil Matcher.explain 'FU', 'snafu'

  it 'boundary matches are as tight as possible', ->
    assert.same { how: 'boundary', {1, 1}, {6, 2} }, Matcher.explain 'hth', 'hail the howl'

  describe 'with reverse matching (reverse = true specified as an option)', ->
    describe 'handles boundary matches', ->
      it 'handles boundary matches', ->
        m = Matcher { 'spec/aplication_spec.moon' }, reverse: true
        assert.same { 'spec/aplication_spec.moon' }, m('as')

      it 'allows for multiple-character boundaries', ->
        m = Matcher { 'spec/aplication/_spec.moon' }, reverse: true
        assert.same { 'spec/aplication/_spec.moon' }, m('as')

    it 'prefers late occurring exact matches over ones at the start', ->
      c = { 'xmatch me', 'me xmatch' }
      m = Matcher c, reverse: true
      assert.same {
        'me xmatch'
        'xmatch me',
      }, m('mat')

    it 'prefers late occurring boundary matches over ones at the start', ->
      c = { 'match natchos', 'me match now' }
      m = Matcher c, reverse: true
      assert.same {
        'me match now'
        'match natchos',
      }, m('mn')

    it 'still prefers tighter matches to longer ones', ->
      c = { 'an_aardvark', 'a_apple' }

      m = Matcher c, reverse: true
      assert.same {
        'a_apple',
        'an_aardvark',
      }, m('aa')

    it 'still prefers boundary matches over straight ones', ->
      c = { 'some/stuff/here', 'sshopen', 'open/ssh', 'ss xh' }
      m = Matcher c, reverse: true

      assert.same {
        'open/ssh',
        'sshopen',
        'some/stuff/here'
      }, m('ssh')

    it 'explain(search, text) works correctly', ->
      assert.same { how: 'exact', {7, 3} }, Matcher.explain 'aƒl', 'ƒluxsñaƒlux', reverse: true
      assert.same { how: 'boundary', {1, 1}, {5, 1} }, Matcher.explain 'as', 'app_spec.fu', reverse: true

  describe 'with preserve_order = true specified as an option', ->
    it 'preserves order of matches, irrespective of match score', ->
      c = {'xabx0', 'ax_bx1', 'xabx2', 'ax_bx3'}
      m = Matcher c, preserve_order: true
      assert.same c, m('ab')

  describe 'for large data sets', ->
    it 'returns a partial match when more than 1000 items match', ->
      items = for i  = 1, 2000
        "item-#{i}"

      m = Matcher items
      matches, opts = m('item')
      assert.equals 1000, #matches
      assert.is_true opts.partial

      matches, opts = m('item-123')
      assert.is_true #matches < 1000
      assert.is_false opts.partial

    it 'allows slightly more than 1000 when the alternative would be irritating', ->
      items = for i  = 1, 1100
        "item-#{i}"

      m = Matcher items
      matches, opts = m('item')
      assert.equals 1100, #matches
      assert.is_false opts.partial
