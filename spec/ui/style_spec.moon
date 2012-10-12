import style, theme, ActionBuffer from lunar.ui
import Scintilla, Buffer from lunar

describe 'style', ->
  it 'styles can be accessed using direct indexing', ->
    t = styles: default: color: '#998877'
    style.set_for_theme t
    assert_equal style.default.color, t.styles.default.color

  describe '.define_style(name, style)', ->
    it 'allows defining custom styles', ->
      style.define 'custom', color: '#334455'
      assert_equal style.custom.color, '#334455'

    it 'automatically redefines the style in any existing sci', ->
      style.define 'keyword', color: '#334455'
      style.define 'custom', color: '#334455'

      sci = Scintilla!
      buffer = Buffer {}, sci
      style.register_sci sci
      custom_number = style.number_for 'custom', buffer
      keyword_number = style.number_for 'keyword', buffer

      style.define 'keyword', color: '#665544'
      style.define 'custom', color: '#776655'

      keyword_fore = sci\style_get_fore keyword_number
      assert_equal keyword_fore, '#665544'

      custom_fore = sci\style_get_fore custom_number
      assert_equal custom_fore, '#776655'

  describe '.number_for(name, buffer)', ->
    it 'returns the assigned style number for name in sci', ->
      assert_equal style.number_for('keyword'), 5 -- default keyword number

    it 'automatically assigns a style number and defines the style in scis if necessary', ->
      sci = Scintilla!
      buffer = Buffer {}, sci
      style.define 'my_style_a', color: '#334455'
      style.define 'my_style_b', color: '#334455'
      style_num = style.number_for 'my_style_a', buffer
      set_fore = sci\style_get_fore style_num
      assert_equal set_fore, '#334455'
      assert_not_equal style.number_for('my_style_b', buffer, sci), style_num

    it 'remembers the style number used for a particular style', ->
      sci = Scintilla!
      buffer = Buffer {}, sci
      style.define 'got_it', color: '#334455'
      style_num = style.number_for 'got_it', buffer
      style_num2 = style.number_for 'got_it', buffer
      assert_equal style_num2, style_num

    it 'raises an error if the number of styles are exhausted', ->
      sci = Scintilla!
      buffer = Buffer {}, sci

      for i = 1, 255 style.define 'my_style' .. i, color: '#334455'

      assert_raises 'Out of style number', ->
        for i = 1, 255 style.number_for 'my_style' .. i, buffer

    it 'returns the default style number if the style is not defined', ->
      assert_equal style.number_for('foo', {}, sci), style.number_for('default', {}, {})

  it '.name_for(number, buffer, sci) returns the style name for number', ->
    assert_equal style.name_for(5, {}), 'keyword' -- default keyword number

    style.define 'whats_in_a_name', color: '#334455'
    buffer = Buffer {}
    style_num = style.number_for 'whats_in_a_name', buffer
    assert_equal style.name_for(style_num, buffer), 'whats_in_a_name'

  describe '.register_sci(sci, default_style)', ->
    it 'defines the default styles in the specified sci', ->
      t = theme.current
      t.styles.keyword = color: '#112233'
      style.set_for_theme t

      sci = Scintilla!
      buffer = Buffer {}
      number = style.number_for 'keyword', buffer
      old = sci\style_get_fore number
      style.register_sci sci
      new = sci\style_get_fore number
      assert_not_equal new, old
      assert_equal new, t.styles.keyword.color

    it 'allows specifying a different default style through <default_style>', ->
      t = theme.current
      t.styles.keyword = color: '#223344'
      style.set_for_theme t

      sci = Scintilla!
      style.register_sci sci, style.keyword
      def_fore = sci\style_get_fore style.number_for 'default', {}
      assert_equal def_fore, t.styles.keyword.color

  it '.set_for_buffer(sci, buffer) initializes any previously used buffer styles', ->
    sci = Scintilla!
    sci2 = Scintilla!
    buffer = Buffer {}, sci

    style.define 'style_foo', color: '#334455'
    prev_number = style.number_for 'style_foo', buffer
    style.set_for_buffer sci2, buffer

    defined_fore = sci2\style_get_fore prev_number
    assert_equal defined_fore, '#334455'

    new_number = style.number_for 'style_foo', buffer, sci2
    assert_equal new_number, prev_number

  it '.at_pos(buffer, pos) returns name and style definition at pos', ->
    style.define 'stylish', color: '#101010'
    buffer = ActionBuffer!
    buffer\insert 'super ', 1, 'keyword'
    buffer\insert 'stylish', 7, 'stylish'

    name, def = style.at_pos(buffer, 6)
    assert_equal name, 'keyword'
    assert_table_equal def, style.keyword

    name, def = style.at_pos(buffer, 7)
    assert_equal name, 'stylish'
    assert_table_equal def, style.stylish

