import highlight, theme, ActionBuffer from lunar.ui
import Scintilla, Buffer from lunar

describe 'highlight', ->
  indicator_on = (buffer, pos, number) ->
    on = buffer.sci\indicator_all_on_for pos - 1
    return on and bit.band(on, number + 1) != 0

  describe '.define(name, definition)', ->
    it 'defines a highlight', ->
      highlight.define 'custom', color: '#334455'
      assert_equal highlight.custom.color, '#334455'

    it 'automatically redefines the highlight in any existing sci', ->
      highlight.define 'custom', color: '#334455'

      sci = Scintilla!
      buffer = Buffer {}, sci
      number = highlight.number_for 'custom', buffer

      highlight.define 'custom', color: '#665544'

      set_fore = buffer.sci\indic_get_fore number
      assert_equal set_fore, '#665544'

  describe '.apply(name, buffer, pos, length)', ->
    it 'activates the highlight for the specified range', ->
      buffer = Buffer {}
      buffer.text = 'hello'
      highlight.define 'custom', color: '#334455'
      number = highlight.number_for 'custom', buffer
      highlight.apply 'custom', buffer, 2, 2

      assert_false indicator_on buffer, 1, number
      assert_true indicator_on buffer, 2, number
      assert_true indicator_on buffer, 3, number
      assert_false indicator_on buffer, 4, number

  describe '.number_for(name, buffer, sci)', ->
    it 'automatically assigns an indicator number and defines the highlight in sci', ->
      buffer = Buffer {}, Scintilla!
      highlight.define 'my_highlight_a', color: '#334455'
      highlight.define 'my_highlight_b', color: '#334455'
      highlight_num = highlight.number_for 'my_highlight_a', buffer
      set_fore = buffer.sci\indic_get_fore highlight_num
      assert_equal set_fore, '#334455'
      assert_not_equal highlight.number_for('my_highlight_b', buffer), highlight_num

    it 'remembers the highlight number used for a particular highlight', ->
      buffer = Buffer {}
      highlight.define 'got_it', color: '#334455'
      highlight_num = highlight.number_for 'got_it', buffer
      highlight_num2 = highlight.number_for 'got_it', buffer
      assert_equal highlight_num2, highlight_num

    it 'raises an error if the number of highlights are exhausted', ->
      buffer = Buffer {}

      for i = 1, Scintilla.INDIC_MAX + 2
        highlight.define 'my_highlight' .. i, color: '#334455'

      assert_raises 'highlights exceeded', ->
        for i = 1, Scintilla.INDIC_MAX + 2
          highlight.number_for 'my_highlight' .. i, buffer

    it 'raises an error if the highlight is not defined', ->
      assert_raises 'Could not find highlight', -> highlight.number_for 'foo', {}

  it '.set_for_buffer(sci, buffer) initializes any previously used buffer highlights', ->
    sci = Scintilla!
    buffer = Buffer {}

    highlight.define 'highlight_foo', color: '#334455'
    number = highlight.number_for 'highlight_foo', buffer
    highlight.set_for_buffer sci, buffer

    defined_fore = sci\indic_get_fore number
    assert_equal defined_fore, '#334455'

  it '.at_pos(buffer, pos) returns a list of the active highlights at pos', ->
    highlight.define 'highlight_bar', color: '#334455'
    highlight.define 'highlight_foo', color: '#334455'
    buffer = Buffer {}
    buffer.text = 'hello'
    highlight.apply 'highlight_bar', buffer, 1, 4
    assert_table_equal highlight.at_pos(buffer, 1), { 'highlight_bar' }
    assert_table_equal highlight.at_pos(buffer, 5), { }

  it '.remove_all(name, buffer) removes all highlights with <name> in <buffer>', ->
    highlight.define 'foo', color: '#334455'
    buffer = Buffer {}
    buffer.text = 'one two'
    highlight.apply 'foo', buffer, 1, 3
    highlight.apply 'foo', buffer, 5, 3
    highlight.remove_all 'foo', buffer
    assert_table_equal highlight.at_pos(buffer, 1), { }
    assert_table_equal highlight.at_pos(buffer, 5), { }
