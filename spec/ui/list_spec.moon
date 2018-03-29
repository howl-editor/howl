-- Copyright 2012-2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
match = require 'luassert.match'

{:Buffer} = howl
{:ActionBuffer, :List, :style, :highlight} = howl.ui
{:Matcher} = howl.util

describe 'List', ->
  local list, buf, items

  before_each ->
    buf = ActionBuffer!
    list = List -> items
    list\insert buf

  list_size = ->
    #[l for l in *buf.lines when not l.is_blank]

  it 'shows single column items, each on one line', ->
    items = {'one', 'two', 'three'}
    list\update!
    assert.equal 'one  \ntwo  \nthree\n', buf.text

  it 'allows items to be Chunks', ->
    source_buf = Buffer!
    source_buf.text = 'source'
    chunk = source_buf\chunk 1, 6
    items = { chunk }
    list\update!
    assert.equal 'source\n', buf.text

  it '.rows_shown is the number of rows drawn for the list', ->
    items = {'one', 'two'}
    list\update!
    assert.equal 'one\ntwo\n', buf.text
    assert.equal 2, list.rows_shown

  context 'matcher integration', ->
    it 'shows matching items only, when update(match_text) called', ->
      list.matcher = Matcher {'one', 'twö', 'three'}
      list\update 'o'
      assert.equal 'one\n', buf.text

    it 'highlights matching parts of text with list_highlight', ->
      list.matcher = Matcher {'one', 'twö', 'three'}
      list\update 'ne'
      assert.equal 'one\n', buf.text

      assert.not_includes highlight.at_pos(buf, 1), 'list_highlight'
      assert.includes highlight.at_pos(buf, 2), 'list_highlight'
      assert.includes highlight.at_pos(buf, 3), 'list_highlight'

    it 'handles higlighting of multibyte chars', ->
      list.matcher = Matcher {'åne', 'twö'}
      list\update 'ån'
      assert.equal 'åne\n', buf.text

      assert.includes highlight.at_pos(buf, 1), 'list_highlight'
      assert.includes highlight.at_pos(buf, 2), 'list_highlight'
      assert.not_includes highlight.at_pos(buf, 3), 'list_highlight'

  it 'shows multi column items each on one line, in separate columns', ->
    items = {
      {'first', 'item one'},
      {'second', 'item two'}
    }
    list.columns = { {}, {} }
    list\update!
    assert.equal [[
first  item one
second item two
]], buf.text

  it 'shows "(no items)" for an empty list', ->
    items = {}
    list\update!
    assert.equal '(no items)\n', buf.text
    assert.equal 1, list.rows_shown

  it 'shows headers, if given, above the items', ->
    items = { {'first', 'item one'} }
    list.columns = { {header: 'Header 1'}, {header: 'Header 2'} }
    list\update!
    assert.equal [[
Header 1 Header 2
first    item one
]], buf.text
    assert.equal 2, list.rows_shown

  context 'when .max_rows is set', ->
    it 'shows only up to max_rows rows', ->
      items = {'one', 'two', 'three'}
      list.max_rows = 2
      list\update!
      assert.equal 2, list_size!
      assert.match buf.text, 'one'
      assert.is_not.match buf.text, 'two'
      assert.equal 2, list.rows_shown
      assert.equal 1, list.page_size

      list.max_rows = math.huge
      list\update!
      assert.equal 'one  \ntwo  \nthree\n', buf.text
      assert.equal 3, list.rows_shown
      assert.equal 3, list.page_size

    it 'errors if height is insufficient to show at least one item', ->
      items = {'one', 'two' }
      list.max_rows = 0
      assert.raises 'insufficient height', -> list\update!

    it 'it takes headers into account when set', ->
      items = {'one', 'two', 'three'}
      list.columns = { {header:'Takes up one line' } }
      list.max_rows = 3
      list\update!
      assert.match buf.text, 'one'
      assert.is_not.match buf.text, 'two'
      assert.equal 3, list.rows_shown
      assert.equal 1, list.page_size

    it 'displays info about the currently shown items', ->
      items = {'one', 'two', 'three'}
      list.max_rows = 2
      list\update!
      assert.match buf.text, 'showing 1 to 1 out of 3'

  context 'when .min_rows is set', ->
    it 'is ignored when the list is bigger than the value', ->
      items = {'one', 'two', 'three'}
      list.min_rows = 1
      list\update!
      assert.equals 3, list_size!

    it 'adds lines to ensure the given value', ->
      items = {}
      list.min_rows = 3
      list\update!
      assert.equals '~\n~\n(no items)\n', buf.text
      assert.equal 3, list.rows_shown

      items = {'one'}
      list.min_rows = 5
      list\update!
      assert.equals 'one\n~\n~\n~\n~\n', buf.text
      assert.equal 5, list.rows_shown

    it 'sets .filler_text for each filler line if specified', ->
      items = {'one'}
      list.opts.filler_text = '##'
      list.min_rows = 2
      list\update!
      assert.equals 'one\n##\n', buf.text

  it 'all properties can be changed after initial assignment', ->
    items = { 'one', 'two' }
    list\update!
    assert.equal buf.text, 'one\ntwo\n'
    items = { 'three', 'four' }
    list\update!
    assert.equal buf.text, 'three\nfour \n'

    items = { { 'three', 'four' } }
    list\update!
    list.columns = { { header: 'Header 1' }, { header: 'Header 2' } }
    list\update!
    assert.equal [[
Header 1 Header 2
three    four    ]] .. '\n', buf.text

  context 'when items are not strings', ->
    it 'automatically converts items to strings using tostring before displaying', ->
      items = { 1, 2 }
      list\update!
      assert.equal '1\n2\n', buf.text

    it 'the selection is still the raw item', ->
      items = { 57, 59 }
      list\update!
      assert.equal list.selection, 57

  describe 'styling', ->
    it 'headers are styled using the list_header style', ->
      items = { { 'one' } }
      list.columns = { { header: 'Header 1' } }
      list\update!
      header_style = style.at_pos(buf, 1)
      assert.equal 'list_header', header_style

    it 'columns are styled using the styles specified in .columns[i].style', ->
      items = { { 'first', 'second' } }
      list.columns = { { style: 'keyword'}, { style: 'identifier' } }
      list\update!
      assert.equal 'keyword', style.at_pos(buf, 1)
      assert.equal 'identifier', style.at_pos(buf, 7)

  context 'selection', ->
    before_each ->
      items = { 'one', 'two', 'three' }
      list\update!

    it 'selects the first item by default', ->
      assert.equal 'one', list.selection

    it '.selection is nil for an empty list', ->
      items = {}
      list\update!
      assert.is_nil list.selection

    it 'highlights the selected item with list_selection', ->
      assert.same { 'list_selection' }, highlight.at_pos(buf, 1)
      assert.same {}, highlight.at_pos(buf, buf.lines[2].start_pos)

    it 'adjusts highlight when headers present', ->
      list.columns = { { header: 'Head' } }
      list\update!
      assert.same {}, highlight.at_pos(buf, 1)
      assert.same { 'list_selection' }, highlight.at_pos(buf, buf.lines[2].start_pos)

    it 'pads lines if neccessary to achieve a uniform selection highlight', ->
      assert.equal 5, #buf.lines[1]
      assert.equal 5, #buf.lines[3]

    describe '.selection = <item>', ->
      it 'causes <item> to be selected', ->
        list.selection = 'two'
        assert.equal list.selection, 'two'

      it 'raises an error if <item> can not be found', ->
        assert.raises 'not found', -> list.selection = 'five'

      it 'highlights the new selection and clears any old highlight', ->
        list.selection = 'one'
        assert.same highlight.at_pos(buf, 1), { 'list_selection' }
        list.selection = 'two'
        assert.same { 'list_selection' }, highlight.at_pos(buf, buf.lines[2].start_pos)
        assert.same {}, highlight.at_pos(buf, 1)

      it 'scrolls the list if needed', ->
        list.max_rows = 2
        list\update!
        list.selection = 'three'
        assert.match buf.text, 'three'

    describe 'select_next()', ->
      it 'selects the next item', ->
        list\select_next!
        assert.equal 'two', list.selection

      it 'selects the first item if at the end of the list', ->
        list.selection = 'three'
        list\select_next!
        assert.equal 'one', list.selection

      it 'scrolls to the item if neccessary', ->
        list.max_rows = 2
        list\update!
        list\select_next!
        assert.equal 'two', list.selection
        assert.match buf.text, 'two'

    describe 'select_prev()', ->
      it 'selects the previous item', ->
        list.selection = 'three'
        list\select_prev!
        assert.equal 'two', list.selection

      it 'selects the last item if at the start of the list', ->
        list\select_prev!
        assert.equal list.selection, 'three'

      it 'scrolls to the item if neccessary', ->
        list.max_rows = 2
        list\update!
        list.selection = 'three'
        list\select_prev!
        assert.equal 'two', list.selection
        assert.match buf.text, 'two'

  describe 'next_page()', ->
    it 'scrolls to the next page', ->
      items = {'one', 'two', 'three'}
      list.max_rows = 2
      list\update!
      list\next_page!
      assert.equal 2, list.offset

    it 'scrolls to the first page if at the end of the list', ->
      items = {'one', 'two', 'three'}
      list.max_rows = 2
      list\update!
      list.selection = 'three'
      list\next_page!
      assert.equal 1, list.offset

  describe 'prev_page()', ->
    it 'scrolls to the previous page', ->
      items = {'one', 'two', 'three'}
      list.max_rows = 2
      list\update!
      list.selection = 'three'
      list\prev_page!
      assert.equal list.offset, 2

    it 'scrolls to the last page if at the start of the list', ->
      items = {'one', 'two', 'three'}
      list.max_rows = 2
      list\update!
      list\prev_page!
      assert.equal list.offset, 3

  context 'when reverse is true', ->

    before_each ->
      items = { 'one', 'two', 'three' }
      list\remove!
      list = List (-> items), reverse: true
      list\insert buf
      list\update!

    it 'shows the items in reverse order', ->
      assert.equal 'three\ntwo  \none  \n', buf.text

    it 'selects the last item by default', ->
      assert.equal 'one', list.selection

  describe 'on_refresh(listener)', ->
    it 'causes <listener> to be called whenever the list is redrawn', ->
      listener = spy.new -> nil
      list\on_refresh listener
      list\update!
      assert.spy(listener).was_called_with match.is_ref(list)

      listener2 = spy.new -> nil
      list\on_refresh listener2
      list\draw!
      assert.spy(listener2).was_called_with match.is_ref(list)

  describe 'display management', ->
    it 'is drawn at the given insert position', ->
      items = {'item'}
      buf.text = '123\n567'
      list\insert buf, 5
      list\update!
      assert.equal '123\nitem\n567', buf.text
      assert.equal 5, list.start_pos

    it 'moves along with other edits in the buffer', ->
      items = {'item'}
      buf.text = '1\n7'
      list\insert buf, 3
      list\update!
      assert.equal '1\nitem\n7', buf.text

      buf\insert '23', 2
      list\draw!
      assert.equal '123\nitem\n7', buf.text
      assert.equal 5, list.start_pos

      buf\insert '56', 10
      list\draw!
      assert.equal '123\nitem\n567', buf.text
      assert.equal 5, list.start_pos

      buf\delete 1, 4
      list\draw!
      assert.equal 'item\n567', buf.text
      assert.equal 1, list.start_pos

      buf\insert 'X', 1
      list\draw!
      assert.equal 'Xitem\n567', buf.text
      assert.equal 2, list.start_pos

  describe 'item_at(pos)', ->
    it 'returns the item at <pos> in the buffer', ->
      items = {'item'}
      buf.text = 'X\nY'
      list\insert buf, 3
      list\update!
      assert.equal 'X\nitem\nY', buf.text
      assert.is_nil list\item_at(1)
      assert.is_nil list\item_at(2)
      assert.equal 'item', list\item_at(3)
      assert.equal 'item', list\item_at(7)
      assert.is_nil list\item_at(8)

      buf\insert '\n', 2
      assert.is_nil list\item_at(3)
      assert.equal 'item', list\item_at(4)
