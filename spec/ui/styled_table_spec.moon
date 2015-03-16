-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import Buffer from howl
import StyledTable, StyledText from howl.ui

render = (t) -> table.concat [tostring item for item in *t]

describe 'StyledTable', ->
  it 'returns a table containing rows padded and newline terminated', ->
    assert.equal 'one  \ntwo  \nthree\n', render StyledTable {'one', 'two', 'three'}

  it 'converts numbers to string', ->
    tbl = StyledTable { 33 }
    assert.includes tbl, '33'

  context 'when items contain chunks', ->
    buf = Buffer!
    buf.text = ' two '
    chunk = buf\chunk 2, 4

    it 'preserves chunks intact', ->
      assert.includes StyledTable({'one', chunk, 'three'}), chunk

    it 'pads chunks correctly', ->
      tbl = StyledTable {'one', chunk, 'three'}
      assert.equal 'one  \ntwo  \nthree\n', render tbl

  context 'when column style is provided', ->
    it 'applies column style', ->
      tbl = StyledTable { 'one' }, { {style: 'string'} }
      assert.includes tbl, StyledText 'one', {1, 'string', 4}


    it 'StyledText objects are left intact', ->
      tbl = StyledTable {'one', StyledText('a', {1, 'string', 2}), 'three'}, {
        { style: 'comment' }
      }
      assert.includes tbl, StyledText('a', {1, 'string', 2})
      assert.includes tbl, StyledText('one', {1, 'comment', 4})

  context 'when a header is provided', ->
    it 'includes header row', ->
      assert.equal 'Header\none   \n', render StyledTable { 'one' }, { {header: 'Header'}}

    it 'pads header', ->
      assert.equal 'Head      \nfirst item\n', render StyledTable { 'first item' }, { {header: 'Head'}}

    it 'styles headers with header_list', ->
      tbl = StyledTable { 'one' }, { {header: 'Head'} }
      assert.includes tbl, StyledText('Head', {1, 'list_header', 5})

  context 'when multiple columns are provided', ->
    it 'returns a table containing multi columns rows', ->
      assert.equal 'one   first \ntwo   second\nthree third \n', render StyledTable {
        {'one', 'first'}
        {'two', 'second'}
        {'three', 'third'}
      }

    it 'columns can each have a header', ->
      assert.equal 'Head1 Head2\none   two  \n', render StyledTable { {'one', 'two'} }, { {header: 'Head1'}, {header: 'Head2'} }

    it 'displays nothing for nil items', ->
      assert.equal 'one   a  \n      two\nthree    \n', render StyledTable {
        {'one', 'a'}
        {nil, 'two'}
        {'three', nil}
      }, { {}, {} }
