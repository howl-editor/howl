-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import StyledText from howl.ui
import Buffer from howl

serpent = require 'serpent'

describe 'StyledText', ->

  it 'has a type of StyledText', ->
    assert.equal 'StyledText', typeof StyledText('foo', {})

  it 'responds to tostring correctly', ->
    assert.equal 'my_text', tostring StyledText('my_text', {})

  it 'responds to the length operator (#)', ->
    assert.equal 7, #StyledText('my_text', {})

  describe 'concatenation', ->
    it 'can be concatenated with strings', ->
      st = StyledText('foo', {})
      assert.equal 'foobar', st .. 'bar'
      assert.equal 'barfoo', 'bar' .. st

    it 'can be concatenated with StyledText to produce StyledText', ->
      st1 = StyledText('foö', {1, 'string', 5})
      st2 = StyledText('1234', {1, 'number', 5})
      assert.equal StyledText('foö1234', {1, 'string', 5, 5, 'number', 9}), st1 .. st2

    it 'supports sub lexing when concatenating styles', ->
      st1 = StyledText('one', {1, {1, 'first', 4}, 'my_sub|base'})
      st2 = StyledText('two', {1, 'second', 4})

      assert.equal StyledText('onetwo', {
        1, {1, 'first', 4}, 'my_sub|base',
        4, 'second', 7
      }), st1 .. st2

      assert.equal StyledText('twoone', {
        1, 'second', 4
        4, {1, 'first', 4}, 'my_sub|base',
      }), st2 .. st1

  it 'can be instantiated using a string-style instead of a style table', ->
    st = StyledText('foo', 'style')
    assert.same {1, 'style', 4}, st.styles

  it 'defers to the string meta table', ->
    st = StyledText('xåäö', {})
    assert.equal 'x', st\sub 1, 1
    assert.equal 'å', st\usub 2, 2
    assert.equal 4, st.ulen

  it 'is equal to other StyledText instances with the same values', ->
    assert.equal StyledText('foo', {}), StyledText('foo', {})
    assert.equal StyledText('foo', {1, 'number', 3}), StyledText('foo', {1, 'number', 3})
    assert.not_equal StyledText('fo1', {1, 'number', 3}), StyledText('foo', {1, 'number', 3})
    assert.not_equal StyledText('foo', {1, 'number', 2}), StyledText('foo', {1, 'number', 3})

  it 'serializable by serpent into a table', ->
    st = StyledText 'text', {1, 'string', 2}
    _, copy = serpent.load serpent.dump(st)
    assert.equal 'text', copy.text
    assert.same {1, 'string', 2}, copy.styles

  context 'for_table', ->
    it 'returns a table containing rows padded and newline terminated', ->
      assert.equal 'one  \ntwo  \nthree\n', tostring StyledText.for_table {'one', 'two', 'three'}

    it 'converts numbers to string', ->
      tbl = StyledText.for_table { 33 }
      assert.includes tostring(tbl), '33'

    context 'when items contain chunks', ->

      it 'pads chunks correctly', ->
        buf = Buffer!
        buf.text = ' twë '
        chunk = buf\chunk 2, 4
        tbl = StyledText.for_table {'onë', chunk, 'three'}
        assert.equal 'onë  \ntwë  \nthree\n', tostring tbl

      it 'preserves chunks styles', ->
        buf = howl.ui.ActionBuffer!
        buf\append 'hëllo', 'string'
        chunk = buf\chunk 1, 5

        tbl = StyledText.for_table {chunk, chunk}
        assert.equal 'hëllo\nhëllo\n', tostring tbl
        assert.same {1, 'string', 7, 8, 'string', 14}, tbl.styles

    it 'allows for items to be StyledText instances', ->
      tbl = StyledText.for_table {'one', StyledText('two', {1, 'string', 4})}
      assert.same {5, 'string', 8}, tbl.styles

    it 'supports sub lexing in the styles', ->
      sub = StyledText('two', {1, {1, 'string', 4}, 'my_sub|base'})
      tbl = StyledText.for_table {sub}
      assert.same sub.styles, tbl.styles

    it 'converts items to StyledText instances if <metatable>.__tostyled exists', ->
      dyn_styled = setmetatable {}, {
        __tostyled: -> StyledText('two', {1, 'string', 4})
        __tostring: -> 'two'
      }

      tbl = StyledText.for_table {'one', dyn_styled}
      assert.same {5, 'string', 8}, tbl.styles

    context 'when column style is provided', ->
      it 'applies column style to text and padding', ->
        tbl = StyledText.for_table { 'one', 'twooo' }, { {style: 'string'} }
        assert.same tbl.text, 'one  \ntwooo\n'
        assert.same tbl.styles, {1, 'string', 4, 4, 'string', 6, 7, 'string', 12}

      it 'preserves style for StyledText objects', ->
        tbl = StyledText.for_table {'one', StyledText('two', {1, 'string', 4}), 'three'}, {
          { style: 'comment' }
        }
        assert.same tbl.styles, {1, 'comment', 4, 4, 'comment', 6, 7, 'string', 10, 10, 'comment', 12, 13, 'comment', 18}

    context 'when column min_width is provided', ->
      it 'pads small cells to respect min_width', ->
        tbl = StyledText.for_table { 'one', 'two' }, { {min_width: 10} }
        assert.same tbl.text, 'one       \ntwo       \n'

      it 'expands column width beyond min_width if necessary', ->
        tbl = StyledText.for_table { 'one', 'twothreefour' }, { {min_width: 4} }
        assert.same tbl.text, 'one         \ntwothreefour\n'

    context 'when max_width is provided', ->
      it 'does not trim when row fits', ->
        tbl = StyledText.for_table { 'one', 'two', 'three'}, {}, max_width: 5
        assert.same 'one  \ntwo  \nthree\n', tbl.text

      it 'trims row and appends [..] to indicate trim', ->
        tbl = StyledText.for_table { 'one one', 'two two', 'three three'}, {}, max_width: 7
        assert.same 'one one\ntwo two\nthr[..]\n', tbl.text

      it 'preserves and trims styling for trimmed cells, uses comment style for [..]', ->
        tbl = StyledText.for_table { StyledText('one one one one', {1, 'string', 15}), 'two', 'three'}, {}, max_width: 5
        assert.same tbl.text, 'o[..]\ntwo  \nthree\n'
        assert.same tbl.styles, {1, 'string', 1, 2, 'comment', 6}

    context 'when column align:"right" is specified', ->
      it 'right aligns the text in the column with one extra space to the right', ->
        tbl = StyledText.for_table { {'o', 'x'}, {'two', 'x'} }, { {align: 'right'} }
        assert.same tbl.text, '  o x\ntwo x\n'

    context 'when a header is provided', ->
      it 'includes header row', ->
        assert.equal 'Header\none   \n', tostring StyledText.for_table { 'one' }, { {header: 'Header'}}

      it 'pads header', ->
        assert.equal 'Heád      \nfirst item\n', tostring StyledText.for_table { 'first item' }, { {header: 'Heád'}}

      it 'styles headers with header_list, including padding', ->
        tbl = StyledText.for_table { 'one-long-column' }, { {header: 'Head'} }
        assert.same tbl.styles, {1, 'list_header', 16}

    context 'when multiple columns are provided', ->
      it 'returns a table containing multi columns rows', ->
        assert.equal 'oná   first \ntwo   second\nthree third \n', tostring StyledText.for_table {
          {'oná', 'first'}
          {'two', 'second'}
          {'three', 'third'}
        }

      it 'columns can each have a header', ->
        assert.equal 'Head1 Head2\none   two  \n', tostring StyledText.for_table { {'one', 'two'} }, { {header: 'Head1'}, {header: 'Head2'} }

      it 'displays nothing for nil items', ->
        assert.equal 'one   a  \n      two\nthree    \n', tostring StyledText.for_table {
          {'one', 'a'}
          {nil, 'two'}
          {'three', nil}
        }, { {}, {} }

    it 'returns a table of column starting positions as the second return value', ->
        st, cols = StyledText.for_table({
          {'123', 'åäö', 'x'}
        })
        assert.equal '123 åäö x\n', tostring(st)
        assert.same {1, 5, 9, num: 3}, cols
