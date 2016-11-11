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

  it 'can be concatenated with strings', ->
    st = StyledText('foo', {})
    assert.equal 'foobar', st .. 'bar'
    assert.equal 'barfoo', 'bar' .. st

  it 'can be concatenated with StyledText to produce StyledText', ->
    st1 = StyledText('foö', {1, 'string', 5})
    st2 = StyledText('1234', {1, 'number', 5})
    assert.equal StyledText('foö1234', {1, 'string', 5, 5, 'number', 9}), st1 .. st2

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

