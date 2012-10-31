import Matcher from lunar.util

describe 'Matcher', ->
  it 'by default it searches anywhere, disregards case and is fuzzy', ->
    m = Matcher {}
    assert.is_true m.anywhere
    assert.is_true m.case_insensitive
    assert.is_true m.fuzzy

  context 'when matching at the start with case sensitive, non-fuzzy set', ->
    it 'matches strictly left to right and respects case', ->
      c = { 'one', 'Overlook', 'two', 'overflow' }
      m = Matcher c, false, false, false
      assert.same m('o'), { 'one', 'overflow' }

  context 'when matching anywhere with case sensitive, non-fuzzy set', ->
    it 'matches the string anywhere and respects case', ->
      c = { 'one', 'Whitehall', 'two', 'overflow' }
      m = Matcher c, true, false, false
      assert.same m('w'), { 'two', 'overflow' }

    it 'prefers early occurring matches over ones at the end', ->
      c = { 'One item', 'item one' }
      m = Matcher c, true, false, false
      assert.same m('item'), { 'item one', 'One item' }

  context 'when matching anywhere with case sensitive, non-fuzzy set', ->
    it 'matches the string anywhere and respects case', ->
      c = { 'one', 'Whitehall', 'two', 'overflow' }
      m = Matcher c, true, false, false
      assert.same m('w'), { 'two', 'overflow' }

  context 'when matching with case insensitive, non-fuzzy set', ->
    it 'matches regardless of case', ->
      c = { 'One', 'Green Fields', 'two', 'overflow' }
      m = Matcher c, true, true, false
      assert.same m('on'), { 'One' }
      assert.same m('Two'), { 'two' }
      assert.same m('fields'), { 'Green Fields' }

  context 'when matching with fuzzy set', ->
    it 'matches if all characters are present', ->
      c = { 'One', 'Green Fields', 'two', 'overflow' }
      m = Matcher c, true, true, true
      assert.same m('ne'), { 'One', 'Green Fields' }

    it 'prefers straight matches over fuzzy ones', ->
      c = { 'One late match at the end', 'hoy en dia no se encuentra' }
      m = Matcher c, true, true, true
      assert.same m('end'), { 'One late match at the end', 'hoy en dia no se encuentra' }

    it 'prefers early occurring matches over ones at the end', ->
      c = { 'Two items to bind them tight', 'One item to match them' }
      m = Matcher c, true, true, true
      assert.same m('ne'), {
        'One item to match them',
        'Two items to bind them tight'
      }

    it 'prefers tighter matches to longer ones', ->
      c = { 'Where joy forever dwells', 'Farewell happy fields' }
      m = Matcher c, true, true, true
      assert.same m('reel'), {
        'Farewell happy fields',
        'Where joy forever dwells'
      }

    it 'escapes any special matching characters in the search string', ->
      c = { 'Item 2. 1%w', 'Item 22 2a' }
      m = Matcher c, true, true, true
      assert.same m('Item 2. 1%w'), { 'Item 2. 1%w' }
