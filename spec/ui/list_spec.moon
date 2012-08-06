import List, Cursor, style, ActionBuffer from vilu.ui
import Buffer, Scintilla from vilu

describe 'List', ->
  sci = Scintilla!
  buf = ActionBuffer sci

  before -> buf.text = ''

  it '# returns the number of items', ->
    list = List {'one', 'two', 'three'}
    assert_equal #list, 3

  describe '.render(buffer, pos, start_item, last_item)', ->
    it 'renders single column items each on one line', ->
      list = List {'one', 'two', 'three'}
      list\render buf, 1
      assert_equal buf.text, 'one\ntwo\nthree\n'

    it 'renders multi column items each on one line, in separate columns', ->
      list = List {
        {'first', 'item one'},
        {'second', 'item two'}
      }
      list\render buf, 1
      assert_equal buf.text, [[
first  item one
second item two
]]

    it 'renders headers, if given, above the items', ->
      list = List { {'first', 'item one'} }, { 'Column 1', 'Column 2' }
      list\render buf, 1
      assert_equal buf.text, [[
Column 1 Column 2
first    item one
]]

    context 'when first_item and last_item is given', ->
      it 'renders only items within the range [first_item, last_item)', ->
        list = List {'one', 'two', 'three'}
        list\render buf, 1, 2, 2
        assert_equal buf.text, 'two\n'

    it 'does not change the cursor position for the underlying scintilla', ->
      buf.text = 'hello'
      list = List {'one', 'two'}

      -- when cursor is before insertion
      sci\set_current_pos 2
      list\render buf, 6
      assert_equal sci\get_current_pos!, 2

      -- when cursor is after insertion
      sci\document_end!
      list\render buf, 1
      assert_equal sci\get_current_pos!, #buf.text

  it 'all properties can be changed after initialization', ->
    list = List { 'one', 'two' }
    list.items = { 'three', 'four' }
    list\render buf, 1
    assert_equal buf.text, 'three\nfour\n'

    buf.text = ''
    list.headers = { 'Column 1', 'Column 2' }
    list.items = { { 'three', 'four' } }
    list\render buf, 1
    assert_equal buf.text, [[
Column 1 Column 2
three    four
]]

  describe 'styling', ->
    it 'headers are styled using the list_header style', ->
      list = List { { 'first' } }, { 'Column 1' }
      list\render buf, 1
      assert_equal style.at_pos(sci, buf, 1), 'list_header'

    it 'columns are styled using the styles specified in .column_styles', ->
      list = List { { 'first', 'second' } }
      list.column_styles = { 'whitespace', 'identifier' }
      list\render buf, 1
      assert_equal style.at_pos(sci, buf, 1), 'whitespace'
      assert_equal style.at_pos(sci, buf, 7), 'identifier'

    it 'column styles default to List.column_styles', ->
      list = List { { 'first', 'second' } }
      list\render buf, 1
      assert_equal style.at_pos(sci, buf, 1), List.column_styles[1]
      assert_equal style.at_pos(sci, buf, 7), List.column_styles[2]

    context 'when .column_styles is a function', ->
      it 'it is called with the item, row and column and the returned style is used', ->
        item = { 'first', 'item' }
        style_func = (list_item, row, column) ->
          assert_equal list_item, item
          assert_equal row, 1
          column == 1 and 'line_number' or 'bracelight'

        list = List { item }
        list.column_styles = style_func
        list\render buf, 1
        assert_equal style.at_pos(sci, buf, 5), 'line_number'
        assert_equal style.at_pos(sci, buf, 7), 'bracelight'
