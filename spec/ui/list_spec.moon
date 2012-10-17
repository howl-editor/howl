import List, Cursor, style, highlight, ActionBuffer from lunar.ui
import Buffer, Scintilla from lunar

describe 'List', ->
  sci = Scintilla!
  buf = ActionBuffer sci
  list = nil

  before ->
    buf.text = ''
    list = List buf, 1

  it '# returns the number of items', ->
    list.items = {'one', 'two', 'three'}
    assert_equal #list, 3

  it '.showing() returns true if the list is currently showing', ->
    assert_false list.showing
    list.items = {'one'}
    list\show!
    assert_true list.showing

  it 'shows single column items each on one line', ->
    list.items = {'one', 'two', 'three'}
    list\show!
    assert_equal buf.text, 'one\ntwo\nthree\n'

  it 'shows multi column items each on one line, in separate columns', ->
    list.items = {
      {'first', 'item one'},
      {'second', 'item two'}
    }
    list\show!
    assert_equal buf.text, [[
first  item one
second item two
]]

  it 'shows nothing for an empty list', ->
    list.items = {}
    list\show!
    assert_equal buf.text, '\n'

  it 'skips the trailing newline if .trailing_newline is false', ->
    list.items = {'one', 'two'}
    list.trailing_newline = false
    list\show!
    assert_equal buf.text, 'one\ntwo'

  context 'when .caption is set', ->
    it 'shows it above the items', ->
      list.items = { 'first' }
      list.caption = 'This is a fine list:'
      list\show!
      assert_equal buf.text, [[
This is a fine list:
first
]]

  it 'it is styled using the list_caption style', ->
    list.items = { { 'first' } }
    list.caption = 'Caption'
    list\show!
    assert_equal style.at_pos(buf, 1), 'list_caption'

  it 'shows headers, if given, above the items', ->
    list.items = { {'first', 'item one'} }
    list.headers = { 'Column 1', 'Column 2' }
    list\show!
    assert_equal buf.text, [[
Column 1 Column 2
first    item one
]]

  it '.offset is set to the index of the first item shown', ->
    list.items = {'one', 'two', 'three'}
    list\show!
    assert_equal list.offset, 1

  it '.last_shown is set to the index of the last item shown', ->
    list.items = {'one', 'two', 'three'}
    list\show!
    assert_equal list.last_shown, 3

  context 'when .offset is set', ->
    it 'shows items starting from offset', ->
      list.items = {'one', 'two', 'three'}
      list.offset = 2
      list\show!
      assert_match 'two\nthree', buf.text
      assert_not_match 'one', buf.text

  it 'does not change the cursor position for the underlying scintilla', ->
    buf.text = 'hello'

    -- when cursor is before insertion
    l = List buf, 6
    l.items = {'one', 'two'}
    sci\set_current_pos 2
    l\show!
    assert_equal sci\get_current_pos!, 2

    -- when cursor is after insertion
    l = List buf, 1
    l.items = {'one', 'two'}
    sci\document_end!
    l\show!
    assert_equal sci\get_current_pos!, #buf.text

  context 'when .max_height is set', ->
    it 'with only .items set it shows only up to max_height items', ->
      list.items = {'one', 'two', 'three'}
      list.max_height = 2
      list\show!
      assert_match 'one\ntwo', buf.text
      assert_not_match 'three', buf.text

      list.max_height = math.huge
      list\show!
      assert_equal buf.text, 'one\ntwo\nthree\n'

    it 'it takes caption into account when set', ->
      list.items = {'one', 'two'}
      list.caption = 'Two\nliner'
      list.max_height = 3
      list\show!
      assert_match 'one', buf.text
      assert_not_match 'two', buf.text

    it 'it takes headers into account when set', ->
      list.items = {'one', 'two'}
      list.headers = { 'Takes up one line' }
      list.max_height = 2
      list\show!
      assert_match 'one', buf.text
      assert_not_match 'two', buf.text

    it 'displays info about the currently shown items', ->
      list.items = {'one', 'two', 'three'}
      list.max_height = 2
      list\show!
      assert_match 'showing 1 %- 2 out of 3', buf.text

  it '.nr_shown is set to the amount of items shown', ->
    list.items = {'one', 'two', 'three'}
    list\show!
    assert_equal 3, list.nr_shown

    list.max_height = 2
    list\show!
    assert_equal 2, list.nr_shown

  it 'all properties can be changed after initial assignment', ->
    list.items = { 'one', 'two' }
    list\show!
    list.items = { 'three', 'four' }
    list\show!
    assert_equal buf.text, 'three\nfour\n'

    list.headers = { 'Column 1', 'Column 2' }
    list.items = { { 'three', 'four' } }
    list\show!
    assert_equal buf.text, [[
Column 1 Column 2
three    four
]]

  context 'when items are not strings', ->
    it 'automatically converts items to strings using tostring before displaying', ->
      list.items = { 1, 2 }
      list\show!
      assert_equal buf.text, '1\n2\n'

    it 'the selection is still the raw item', ->
      list.selection_enabled = true
      list.items = { 1, 2 }
      list\show!
      assert_equal list.selection, 1

  describe 'styling', ->
    it 'headers are styled using the list_header style', ->
      list.items = { { 'first' } }
      list.headers = { 'Column 1' }
      list\show!
      assert_equal style.at_pos(buf, 1), 'list_header'

    it 'columns are styled using the styles specified in .column_styles', ->
      list.items = { { 'first', 'second' } }
      list.column_styles = { 'whitespace', 'identifier' }
      list\show!
      assert_equal style.at_pos(buf, 1), 'whitespace'
      assert_equal style.at_pos(buf, 7), 'identifier'

    it 'column styles default to List.column_styles', ->
      list.items = { { 'first', 'second' } }
      list\show!
      assert_equal style.at_pos(buf, 1), List.column_styles[1]
      assert_equal style.at_pos(buf, 7), List.column_styles[2]

    context 'when .column_styles is a function', ->
      it 'it is called with the item, row and column and the returned style is used', ->
        item = { 'first', 'item' }
        style_func = (list_item, row, column) ->
          assert_equal list_item, item
          assert_equal row, 1
          column == 1 and 'line_number' or 'bracelight'

        list.items = { item }
        list.column_styles = style_func
        list\show!
        assert_equal style.at_pos(buf, 5), 'line_number'
        assert_equal style.at_pos(buf, 7), 'bracelight'

  context 'when selection is enabled with .selection_enabled', ->
    before ->
      list.selection_enabled = true
      list.items = { 'one', 'two', 'three' }
      list\show!

    it 'selects the first item by default', ->
      assert_equal list.selection, 'one'

    it '.selection is nil for an empty list', ->
      list.items = {}
      list\show!
      assert_nil list.selection

    it 'highlights the selected item with list_selection', ->
      assert_table_equal highlight.at_pos(buf, 1), { 'list_selection' }
      assert_table_equal highlight.at_pos(buf, 5), {}

    describe '.selection = <item>', ->
      it 'causes <item> to be selected', ->
        list.selection = 'two'
        assert_equal list.selection, 'two'

      it 'raises an error if <item> can not be found', ->
        assert_raises 'not found', -> list.selection = 'five'

      it 'can be set before the list shown', ->
        list\clear!
        list.selection = 'two'
        list\show!
        assert_equal list.selection, 'two'

    describe 'select(row)', ->
      it 'selects the specified row', ->
        list\select 2
        assert_equal list.selection, 'two'

      it 'highlights the new selection and clears any old highlight', ->
        list\select 2
        assert_table_equal highlight.at_pos(buf, 1), {}
        assert_table_equal highlight.at_pos(buf, 5), { 'list_selection' }

      it 'scrolls the list if needed', ->
        list.max_height = 2
        list\show!
        list\select 3
        assert_match 'three', buf.text

      it 'remembers the selected row if set before showing', ->
        list\clear!
        list.max_height = 2
        list\select 3
        list\show!
        assert_equal list.selection, 'three'
        assert_match 'three', buf.text

    describe 'select_next()', ->
      it 'selects the next item', ->
        list\select_next!
        assert_equal list.selection, 'two'

      it 'selects the first item if at the end of the list', ->
        list\select 3
        list\select_next!
        assert_equal list.selection, 'one'

      it 'scrolls to the next item if neccessary', ->
        list.max_height = 1
        list\show!
        list\select_next!
        assert_equal list.selection, 'two'
        assert_equal list.offset, 2

    describe 'select_prev()', ->
      it 'selects the previous item', ->
        list\select 2
        list\select_prev!
        assert_equal list.selection, 'one'

      it 'selects the last item if at the start of the list', ->
        list\select_prev!
        assert_equal list.selection, 'three'

      it 'scrolls so that the previous item is at the bottom if neccessary', ->
        list.items = { 'one', 'two', 'three', 'four' }
        list.max_height = 2
        list.offset = 3
        list\show!
        list\select 3
        list\select_prev!
        assert_equal list.selection, 'two'
        assert_equal list.offset, 1

  describe 'scroll_to(row)', ->
    before -> list.items = {'one', 'two', 'three'}

    it 'does not change offset when all items are shown', ->
      list\show!
      list\scroll_to 2
      assert_match 'one\ntwo\nthree\n', buf.text

    it 'changes the offset to start with <row> when all items are not shown', ->
      list.max_height = 1
      list\show!
      list\scroll_to 2
      assert_match 'two', buf.text
      assert_match 'showing 2 %- 2 out of 3', buf.text

    context 'when the remaining numbers are fewer than the max nr of visible items', ->
      it 'adjust the actual offset to always show the same number of items', ->
        list.max_height = 2
        list\show!
        list\scroll_to 3
        assert_match 'two\nthree', buf.text

      it 'accounts for headers when determining the new offset', ->
        list.headers = { 'foo' }
        list.max_height = 2
        list\show!
        list\scroll_to 3
        assert_match '^foo\nthree', buf.text

    it 'selects <row> if selection is enabled', ->
      list.selection_enabled = true
      list.max_height = 2
      list\show!
      list\scroll_to 3
      assert_equal list.selection, 'three'

  describe '.next_page', ->
    it 'scrolls to the next page', ->
      list.items = {'one', 'two', 'three'}
      list.max_height = 1
      list\show!
      list\next_page!
      assert_equal list.offset, 2

    it 'scrolls to the first page if at the end of the list', ->
      list.items = {'one', 'two', 'three'}
      list.max_height = 1
      list\show!
      list\scroll_to 3
      list\next_page!
      assert_equal list.offset, 1

  describe '.prev_page', ->
    it 'scrolls to the previous page', ->
      list.items = {'one', 'two', 'three'}
      list.max_height = 1
      list\show!
      list\scroll_to 3
      list\prev_page!
      assert_equal list.offset, 2

    it 'scrolls to the last page if at the start of the list', ->
      list.items = {'one', 'two', 'three'}
      list.max_height = 1
      list\show!
      list\prev_page!
      assert_equal list.offset, 3
