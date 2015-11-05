-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import Buffer from howl
import ListWidget, TextWidget, style, highlight from howl.ui
import Matcher from howl.util
s = require 'serpent'

describe 'ListWidget', ->
  local list, buf

  before_each ->
    list = ListWidget -> {}
    list.max_rows_visible = 100
    list\show!
    buf = list.text_widget.buffer

  it 'shows empty list until update() is called', ->
    list = ListWidget -> {'one', 'two', 'three'}
    list\show!
    assert.equal '(no items)', list.text_widget.buffer.text
    list\update!
    assert.not_equal '(no items)', list.text_widget.buffer.text

  it 'shows single column items, each on one line', ->
    list.matcher = -> {'one', 'two', 'three'}
    list\update!
    assert.equal 'one  \ntwo  \nthree\n', buf.text

  it 'allows items to be Chunks', ->
    source_buf = Buffer!
    source_buf.text = 'source'
    chunk = source_buf\chunk 1, 6
    list.matcher = -> { chunk }
    list\update!
    assert.equal 'source\n', buf.text

  context 'matching', ->
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

  context 'when `never_shrink:` is not provided', ->
    it 'shrinks the height while matching', ->
      list.matcher = Matcher {'one', 'twö', 'three'}
      list\update!
      height = list.height
      assert.not_nil height

      list\update 'o'
      assert.equal height / 3, list.height

  context 'when `never_shrink: true` is provided', ->
    it 'does not shrink the height while matching', ->
      list = ListWidget Matcher({'one', 'twö', 'three'}),
        never_shrink: true
      list\show!
      list\update!
      height = list.height
      assert.not_nil height

      list\update 'o'
      assert.equal height, list.height

  it 'shows multi column items each on one line, in separate columns', ->
    list.matcher = -> {
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
    list.matcher = -> {}
    list\update!
    assert.equal '(no items)', buf.text

  it 'shows headers, if given, above the items', ->
    list.matcher = -> { {'first', 'item one'} }
    list.columns = { {header: 'Header 1'}, {header: 'Header 2'} }
    list\update!
    assert.equal [[
Header 1 Header 2
first    item one
]], buf.text

  context 'when .max_visible_rows is set', ->
    it 'shows only up to max_rows_visible rows', ->
      list.matcher = -> {'one', 'two', 'three'}
      list.max_visible_rows = 2
      list\update!
      assert.equal 2, list.visible_rows
      assert.match buf.text, 'one'
      assert.is_not.match buf.text, 'two'

      list.max_visible_rows = math.huge
      list\update!
      assert.equal 'one  \ntwo  \nthree\n', buf.text

    it 'errors if height is insufficient to show at least one item', ->
      list.matcher = -> {'one', 'two' }
      list.max_visible_rows = 0
      assert.raises 'insufficient height', -> list\update!

    it 'it takes headers into account when set', ->
      list.matcher = -> {'one', 'two', 'three'}
      list.columns = { {header:'Takes up one line' } }
      list.max_visible_rows = 3
      list\update!
      assert.match buf.text, 'one'
      assert.is_not.match buf.text, 'two'

    it 'displays info about the currently shown items', ->
      list.matcher = -> {'one', 'two', 'three'}
      list.max_visible_rows = 2
      list\update!
      assert.match buf.text, 'showing 1 to 1 out of 3'

  context 'when .min_visible_rows is set', ->
    it 'is ignored when the list is bigger than the value', ->
      list.matcher = -> {'one', 'two', 'three'}
      list.min_visible_rows = 1
      list\update!
      assert.equals 3, list.visible_rows

    it 'adds lines to ensure the given value', ->
      list.matcher = -> {'one'}
      list.min_visible_rows = 3
      list\update!
      assert.equals 'one\n~\n~\n', buf.text

    it 'sets .filler_text for each filler line if specified', ->
      list.matcher = -> {'one'}
      list.opts.filler_text = '##'
      list.min_visible_rows = 2
      list\update!
      assert.equals 'one\n##\n', buf.text

  describe '.height', ->
    get_row_height = ->
      list.text_widget.view\text_dimensions('M').height

    it 'is set to the number of pixels used for displaying the list', ->
      list.matcher = -> {'one', 'two', 'three'}
      list\update!
      assert.equal 3 * get_row_height(list), list.height

    it 'includes headers', ->
      list.matcher = -> {'one', 'two', 'three'}
      list.columns = { { header: 'Header 1' } }
      list\update!
      assert.equal 4 * get_row_height(list), list.height

  it 'all properties can be changed after initial assignment', ->
    list.matcher = -> { 'one', 'two' }
    list\update!
    assert.equal buf.text, 'one\ntwo\n'
    list.matcher = -> { 'three', 'four' }
    list\update!
    assert.equal buf.text, 'three\nfour \n'

    list.matcher = -> { { 'three', 'four' } }
    list\update!
    list.columns = { { header: 'Header 1' }, { header: 'Header 2' } }
    list\update!
    assert.equal [[
Header 1 Header 2
three    four    ]] .. '\n', buf.text

  context 'when items are not strings', ->
    it 'automatically converts items to strings using tostring before displaying', ->
      list.matcher = -> { 1, 2 }
      list\update!
      assert.equal '1\n2\n', buf.text

    it 'the selection is still the raw item', ->
      list.matcher = -> { 57, 59 }
      list\update!
      assert.equal list.selection, 57

  describe 'styling', ->
    it 'headers are styled using the list_header style', ->
      list.matcher = -> { { 'one' } }
      list.columns = { { header: 'Header 1' } }
      list\update!
      header_style = style.at_pos(buf, 1)
      assert.equal 'list_header', header_style

    it 'columns are styled using the styles specified in .columns[i].style', ->
      list.matcher = -> { { 'first', 'second' } }
      list.columns = { { style: 'keyword'}, { style: 'identifier' } }
      list\update!
      assert.equal 'keyword', style.at_pos(buf, 1)
      assert.equal 'identifier', style.at_pos(buf, 7)

  context 'selection', ->
    before_each ->
      list.matcher = -> { 'one', 'two', 'three' }
      list\update!

    it 'selects the first item by default', ->
      assert.equal 'one', list.selection

    it '.selection is nil for an empty list', ->
      list.matcher = -> {}
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
        list.max_visible_rows = 2
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
        list.max_visible_rows = 2
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
        list.max_visible_rows = 2
        list\update!
        list.selection = 'three'
        list\select_prev!
        assert.equal 'two', list.selection
        assert.match buf.text, 'two'

  describe 'next_page()', ->
    it 'scrolls to the next page', ->
      list.matcher = -> {'one', 'two', 'three'}
      list.max_visible_rows = 2
      list\update!
      list\next_page!
      assert.equal 2, list.offset

    it 'scrolls to the first page if at the end of the list', ->
      list.matcher = -> {'one', 'two', 'three'}
      list.max_visible_rows = 2
      list\update!
      list.selection = 'three'
      list\next_page!
      assert.equal 1, list.offset

  describe 'prev_page()', ->
    it 'scrolls to the previous page', ->
      list.matcher = -> {'one', 'two', 'three'}
      list.max_visible_rows = 2
      list\update!
      list.selection = 'three'
      list\prev_page!
      assert.equal list.offset, 2

    it 'scrolls to the last page if at the start of the list', ->
      list.matcher = -> {'one', 'two', 'three'}
      list.max_visible_rows = 2
      list\update!
      list\prev_page!
      assert.equal list.offset, 3

  context 'when reverse is true', ->
    local rlist, rbuf

    before_each ->
      matcher = -> { 'one', 'two', 'three' }
      rlist = ListWidget matcher, reverse: true
      rlist\show!
      rbuf = rlist.text_widget.buffer
      rlist\update!

    it 'shows the items in reverse order', ->
      assert.equal 'three\ntwo  \none  \n', rbuf.text

    it 'selects the last item by default', ->
      assert.equal 'one', rlist.selection

  context 'resource management', ->

    it 'widgets are collected as they should', ->
      w = ListWidget (->)
      list = setmetatable {w}, __mode: 'v'
      w\to_gobject!\destroy!
      w = nil
      collectgarbage!
      assert.is_nil list[1]

    it 'memory usage is stable', ->
      items = {'one', 'two', 'three'}
      assert_memory_stays_within '30Kb', ->
        for i = 1, 20
          w = ListWidget (-> items)
          w\show!
          w\to_gobject!\destroy!

