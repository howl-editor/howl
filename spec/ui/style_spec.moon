import style, theme from vilu.ui
import Scintilla from vilu

describe 'style', ->
  it '.string_to_color(color) returns a GBR representation of the color', ->
    assert_equal style.string_to_color('#ffeedd'), 0xddeeff
    assert_equal style.string_to_color('ffeedd'), 0xddeeff

  it 'styles can be accessed using direct indexing', ->
    assert_equal style.default.color, theme.current.styles.default.color

  it '.define_style(name, style) allows defining custom styles', ->
    style.define 'custom', color: '#334455'
    assert_equal style.custom.color, '#334455'

  describe '.number_for(name, buffer, sci)', ->
    it 'returns the assigned style number for name in sci', ->
      assert_equal style.number_for('keyword'), 5 -- default keyword number

    it 'automatically assigns a style number and defines the style in sci if necessary', ->
      sci = Scintilla!
      style.define 'my_style_a', color: '#334455'
      style.define 'my_style_b', color: '#334455'
      style_num = style.number_for 'my_style_a', {}, sci
      set_fore = sci\style_get_fore style_num
      assert_equal set_fore, 0x554433
      assert_not_equal style.number_for('my_style_b', {}, sci), style_num0

    it 'remembers the style number used for a particular style', ->
      sci = Scintilla!
      buffer = {}
      style.define 'got_it', color: '#334455'
      style_num = style.number_for 'got_it', buffer, sci
      style_num2 = style.number_for 'got_it', buffer, sci
      assert_equal style_num2, style_num

    it 'raises an error if the number of styles are exhausted', ->
      sci = Scintilla!
      buffer = {}

      for i = 1, 255 style.define 'my_style' .. i, color: '#334455'

      assert_raises 'Out of style number', ->
        for i = 1, 255 style.number_for 'my_style' .. i, buffer, sci

    it 'returns the default style number if the style is not defined', ->
      assert_equal style.number_for('foo', {}, sci), style.number_for('default', {}, {})

  it '.register_sci(sci, buffer) defines the default styles in the specified sci', ->
    t = theme.current
    t.styles.keyword = color: '#112233'
    style.set_for_theme t
    sci = Scintilla!
    number = style.number_for 'keyword', {}, sci
    old = sci\style_get_fore number
    style.register_sci sci, {}
    new = sci\style_get_fore number
    assert_not_equal new, old
    assert_equal new, style.string_to_color '#112233'

  it '.set_for_buffer(sci, buffer) initializes any previously used buffer styles', ->
    sci = Scintilla!
    sci2 = Scintilla!
    buffer = {}

    style.define 'style_foo', color: '#334455'
    prev_number = style.number_for 'style_foo', buffer, sci
    style.set_for_buffer sci2, buffer

    defined_fore = sci2\style_get_fore prev_number
    assert_equal defined_fore, 0x554433

    new_number = style.number_for 'style_foo', buffer, sci2
    assert_equal new_number, prev_number
