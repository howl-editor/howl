import List, Cursor, style, highlight, ActionBuffer from howl.ui
import Buffer, Scintilla from howl

describe 'List', ->
  sci = Scintilla!
  buf = ActionBuffer sci
  sci.listener =
    on_text_inserted: buf\_on_text_inserted
    on_text_deleted: buf\_on_text_deleted

  list = nil

  before_each ->
    buf.text = ''
    list = List buf, 1

  it '# returns the number of items', ->
    list.items = {'one', 'two', 'three'}
    assert.equal #list, 3

  it '.showing() returns true if the list is currently showing', ->
    assert.is_false list.showing
    list.items = {'one'}
    list\show!
    assert.is_true list.showing

  it 'shows single column items each on one line', ->
    list.items = {'one', 'twö', 'three'}
    list\show!
    assert.equal 'one\ntwö\nthree\n', buf.text

  it 'allows items to be Chunks', ->
    source_buf = Buffer!
    source_buf.text = 'source'
    chunk = source_buf\chunk 1, 6
    list.items = { chunk }
    list\show!
    assert.equal 'source\n', buf.text

  it 'shows multi column items each on one line, in separate columns', ->
    list.items = {
      {'first', 'item one'},
      {'second', 'item two'}
    }
    list\show!
    assert.equal buf.text, [[
first  item one
second item two
]]

  it 'shows nothing for an empty list', ->
    list.items = {}
    list\show!
    assert.equal buf.text, '\n'

  it 'skips the trailing newline if .trailing_newline is false', ->
    list.items = {'one', 'two'}
    list.trailing_newline = false
    list\show!
    assert.equal buf.text, 'one\ntwo'

  describe 'clear()', ->
    it 'removes a rendered list from the buffer', ->
      buf.text = '||'
      list = List buf, 2
      list.items = {'one', 'two'}
      list\show!
      list\clear!
      assert.equal '||', buf.text

    it 'does nothing if the list has not been rendered yet or was empty', ->
      buf.text = '||'
      list = List buf, 2
      list\clear!
      assert.equal '||', buf.text

      list.items = {}
      list\show!
      list\clear!
      assert.equal '||', buf.text

  context 'when .caption is set', ->
    it 'shows it above the items', ->
      list.items = { 'first' }
      list.caption = 'This is a fine list:'
      list\show!
      assert.equal buf.text, [[
This is a fine list:
first
]]

  it 'it is styled using the list_caption style', ->
    list.items = { { 'first' } }
    list.caption = 'Caption'
    list\show!
    assert.equal style.at_pos(buf, 1), 'list_caption'

  it 'shows headers, if given, above the items', ->
    list.items = { {'first', 'item one'} }
    list.headers = { 'Column 1', 'Column 2' }
    list\show!
    assert.equal buf.text, [[
Column 1 Column 2
first    item one
]]

  it '.offset is set to the index of the first item shown', ->
    list.items = {'one', 'two', 'three'}
    list\show!
    assert.equal list.offset, 1

  it '.last_shown is set to the index of the last item shown', ->
    list.items = {'one', 'two', 'three'}
    list\show!
    assert.equal list.last_shown, 3

  context 'when .offset is set', ->
    it 'shows items starting from #offset', ->
      list.items = {'one', 'two', 'three'}
      list.offset = 2
      list\show!
      assert.match buf.text, 'two\nthree'
      assert.is_not.match buf.text, 'one'

  it 'does not change the cursor position for the underlying scintilla', ->
    buf.text = 'hello'

    -- when cursor is before insertion
    l = List buf, 6
    l.items = {'one', 'two'}
    sci\set_current_pos 2
    l\show!
    assert.equal sci\get_current_pos!, 2

    -- when cursor is after insertion
    l = List buf, 1
    l.items = {'one', 'two'}
    sci\document_end!
    l\show!
    assert.equal sci\get_current_pos!, #buf.text

  context 'when .max_height is set', ->
    it 'with only .items set it shows only up to max_height lines', ->
      list.items = {'one', 'two', 'three'}
      list.max_height = 2
      list\show!
      assert.match buf.text, 'one'
      assert.is_not.match buf.text, 'two'

      list.max_height = math.huge
      list\show!
      assert.equal 'one\ntwo\nthree\n', buf.text

    it 'it takes caption into account when set', ->
      list.items = {'one', 'two', 'three'}
      list.caption = 'Two\nliner'
      list.max_height = 4
      list\show!
      assert.match buf.text, 'one'
      assert.is_not.match buf.text, 'two'

    it 'it takes headers into account when set', ->
      list.items = {'one', 'two'}
      list.headers = { 'Takes up one line' }
      list.max_height = 2
      list\show!
      assert.match buf.text, 'one'
      assert.is_not.match buf.text, 'two'

    it 'displays info about the currently shown items', ->
      list.items = {'one', 'two', 'three'}
      list.max_height = 2
      list\show!
      assert.match buf.text, 'showing 1 %- 1 out of 3'

  context 'when .min_height is set', ->
    it 'is ignored when the list is bigger than the value', ->
      list.items = {'one', 'two', 'three'}
      list.min_height = 2
      list\show!
      assert.equals 3, list.height

    it 'is ignored when .max_height is greater', ->
      list.items = {'one' }
      list.min_height = 2
      list.max_height = 1
      list\show!
      assert.equals 1, list.height

    it 'adds lines to ensure the given value', ->
      list.items = {'one' }
      list.min_height = 3
      list\show!
      assert.equals 'one\n\n\n', buf.text

    it 'sets .filler_text for each filler line if specified', ->
      list.items = {'one' }
      list.min_height = 2
      list.filler_text = 'X'
      list\show!
      assert.equals 'one\nX\n', buf.text

  it '.nr_shown is set to the amount of items shown', ->
    list.items = {'one', 'two', 'three'}
    list\show!
    assert.equal 3, list.nr_shown

    list.max_height = 2
    list\show!
    assert.equal 1, list.nr_shown

  describe '.height', ->
    it 'is set to the number of lines used for displaying the list', ->
      list.items = {'one', 'two', 'three'}
      list\show!
      assert.equal 3, list.height

    it 'includes headers', ->
      list.items = {'one', 'two', 'three'}
      list.headers = { 'Column 1' }
      list\show!
      assert.equal 4, list.height

    it 'includes caption', ->
      list.items = {'one', 'two'}
      list.caption = 'This is a\nfine list:'
      list\show!
      assert.equal 4, list.height

    it 'accounts for a truncated list', ->
      list.items = {'one', 'two', 'three'}
      list.max_height = 3
      list\show!
      assert.equal 3, list.height

  it 'all properties can be changed after initial assignment', ->
    list.items = { 'one', 'two' }
    list\show!
    list.items = { 'three', 'four' }
    list\show!
    assert.equal buf.text, 'three\nfour\n'

    list.headers = { 'Column 1', 'Column 2' }
    list.items = { { 'three', 'four' } }
    list\show!
    assert.equal buf.text, [[
Column 1 Column 2
three    four
]]

  it 'resets offset when items are reassigned', ->
    list.items = { 'one', 'two', 'three' }
    list.max_height = 2
    list\show!
    list\next_page!
    list.items = { 'one', 'two' }
    list\show!
    assert.match buf.text, '^one'

  context 'when items are not strings', ->
    it 'automatically converts items to strings using tostring before displaying', ->
      list.items = { 1, 2 }
      list\show!
      assert.equal buf.text, '1\n2\n'

    it 'the selection is still the raw item', ->
      list.selection_enabled = true
      list.items = { 1, 2 }
      list\show!
      assert.equal list.selection, 1

  describe 'styling', ->
    it 'headers are styled using the list_header style', ->
      list.items = { { 'first' } }
      list.headers = { 'Column 1' }
      list\show!
      assert.equal style.at_pos(buf, 1), 'list_header'

    it 'columns are styled using the styles specified in .column_styles', ->
      list.items = { { 'first', 'second' } }
      list.column_styles = { 'whitespace', 'identifier' }
      list\show!
      assert.equal style.at_pos(buf, 1), 'whitespace'
      assert.equal style.at_pos(buf, 7), 'identifier'

    it 'column styles default to List.column_styles', ->
      list.items = { { 'first', 'second' } }
      list\show!
      assert.equal style.at_pos(buf, 1), List.column_styles[1]
      assert.equal style.at_pos(buf, 7), List.column_styles[2]

    it '.column_styles can be customized for each instance', ->
      list.column_styles[1] = 'custom'
      assert.not_equal 'custom', List.column_styles[1]

    context 'when .column_styles is a function', ->
      it 'it is called with the item, row and column and the returned style is used', ->
        item = { 'first', 'item' }
        style_func = (list_item, row, column) ->
          assert.equal list_item, item
          assert.equal row, 1
          column == 1 and 'line_number' or 'bracelight'

        list.items = { item }
        list.column_styles = style_func
        list\show!
        assert.equal style.at_pos(buf, 5), 'line_number'
        assert.equal style.at_pos(buf, 7), 'bracelight'

  context 'when selection is enabled with .selection_enabled', ->
    before_each ->
      list.selection_enabled = true
      list.items = { 'one', 'two', 'three' }
      list\show!

    it 'selects the first item by default', ->
      assert.equal 'one', list.selection

    it '.selection is nil for an empty list', ->
      list.items = {}
      list\show!
      assert.is_nil list.selection

    it 'highlights the selected item with list_selection', ->
      assert.same { 'list_selection' }, highlight.at_pos(buf, 1)
      assert.same {}, highlight.at_pos(buf, buf.lines[2].start_pos)

    it 'pads lines if neccessary to achieve a uniform selection highlight', ->
      assert.equal 5, #buf.lines[1]
      assert.equal 5, #buf.lines[3]

    describe '.selection = <item>', ->
      it 'causes <item> to be selected', ->
        list.selection = 'two'
        assert.equal list.selection, 'two'

      it 'raises an error if <item> can not be found', ->
        assert.raises 'not found', -> list.selection = 'five'

      it 'can be set before the list shown', ->
        list\clear!
        list.selection = 'two'
        list\show!
        assert.equal list.selection, 'two'

    describe 'select(row)', ->
      it 'selects the specified row', ->
        list\select 2
        assert.equal list.selection, 'two'

      it 'highlights the new selection and clears any old highlight', ->
        list\select 2
        assert.same highlight.at_pos(buf, 1), {}
        assert.same highlight.at_pos(buf, buf.lines[2].start_pos), { 'list_selection' }

      it 'scrolls the list if needed', ->
        list.max_height = 2
        list\show!
        list\select 3
        assert.match buf.text, 'three'

      it 'remembers the selected row if set before showing', ->
        list\clear!
        list.max_height = 2
        list\select 3
        list\show!
        assert.equal list.selection, 'three'
        assert.match buf.text, 'three'

    describe 'select_next()', ->
      it 'selects the next item', ->
        list\select_next!
        assert.equal list.selection, 'two'

      it 'selects the first item if at the end of the list', ->
        list\select 3
        list\select_next!
        assert.equal list.selection, 'one'

      it 'scrolls to the next item if neccessary', ->
        list.max_height = 2
        list\show!
        list\select_next!
        assert.equal list.selection, 'two'
        assert.equal list.offset, 2

    describe 'select_prev()', ->
      it 'selects the previous item', ->
        list\select 2
        list\select_prev!
        assert.equal list.selection, 'one'

      it 'selects the last item if at the start of the list', ->
        list\select_prev!
        assert.equal list.selection, 'three'

      it 'scrolls so that the previous item is at the bottom if neccessary', ->
        list.items = { 'one', 'two', 'three', 'four' }
        list.max_height = 3
        list.offset = 3
        list\show!
        list\select 3
        list\select_prev!
        assert.equal list.selection, 'two'
        assert.equal list.offset, 1

  describe 'scroll_to(row)', ->
    before_each -> list.items = {'one', 'two', 'three'}

    it 'does not change offset when all items are shown', ->
      list\show!
      list\scroll_to 2
      assert.match buf.text, 'one\ntwo\nthree\n'

    it 'changes the offset to start with <row> when all items are not shown', ->
      list.max_height = 2
      list\show!
      list\scroll_to 2
      assert.match buf.text, 'two'
      assert.match buf.text, 'showing 2 %- 2 out of 3'

    context 'when the remaining numbers are fewer than the max nr of visible items', ->
      it 'adjust the actual offset to always show the same number of items', ->
        list.max_height = 3
        list\show!
        list\scroll_to 3
        assert.match buf.text, 'two\nthree'

      it 'accounts for headers when determining the new offset', ->
        list.headers = { 'foo' }
        list.max_height = 3
        list\show!
        list\scroll_to 3
        assert.match buf.text, '^foo\nthree'

    it 'selects <row> if selection is enabled', ->
      list.selection_enabled = true
      list.max_height = 2
      list\show!
      list\scroll_to 3
      assert.equal list.selection, 'three'

  describe 'next_page()', ->
    it 'scrolls to the next page', ->
      list.items = {'one', 'two', 'three'}
      list.max_height = 2
      list\show!
      list\next_page!
      assert.equal 2, list.offset

    it 'scrolls to the first page if at the end of the list', ->
      list.items = {'one', 'two', 'three'}
      list.max_height = 2
      list\show!
      list\scroll_to 3
      list\next_page!
      assert.equal 1, list.offset

  describe 'prev_page()', ->
    it 'scrolls to the previous page', ->
      list.items = {'one', 'two', 'three'}
      list.max_height = 2
      list\show!
      list\scroll_to 3
      list\prev_page!
      assert.equal list.offset, 2

    it 'scrolls to the last page if at the start of the list', ->
      list.items = {'one', 'two', 'three'}
      list.max_height = 2
      list\show!
      list\prev_page!
      assert.equal list.offset, 3
