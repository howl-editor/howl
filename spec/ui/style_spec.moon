import style, theme, ActionBuffer from howl.ui
import Scintilla, Buffer, config from howl

describe 'style', ->
  local sci, buffer

  before_each ->
      sci = Scintilla!
      buffer = Buffer {}, sci
      style.register_sci sci

  it 'styles can be accessed using direct indexing', ->
    t = styles: default: color: '#998877'
    style.set_for_theme t
    assert.equal style.default.color, t.styles.default.color

  describe '.define(name, definition)', ->
    it 'allows defining custom styles', ->
      style.define 'custom', color: '#334455'
      assert.equal style.custom.color, '#334455'

    it 'automatically redefines the style in any existing sci', ->
      style.define 'keyword', color: '#334455'
      style.define 'custom', color: '#334455'

      custom_number = style.number_for 'custom', buffer
      keyword_number = style.number_for 'keyword', buffer

      style.define 'keyword', color: '#665544'
      style.define 'custom', color: '#776655'

      keyword_fore = sci\style_get_fore keyword_number
      assert.equal '#665544', keyword_fore

      custom_fore = sci\style_get_fore custom_number
      assert.equal '#776655', custom_fore

    it 'allows specifying font size for a style as an offset spec from "font_size"', ->
      style.define 'larger_style', font: size: 'larger'
      style_number = style.number_for 'larger_style', buffer
      font_size = sci\style_get_size style_number
      assert.is_true font_size > config.font_size

    it 'allows aliasing styles using a string as <definition>', ->
      style.define 'target', color: '#beefed'
      style.define 'alias', 'target'
      style_number = style.number_for 'alias', buffer
      assert.equal '#beefed', sci\style_get_fore style_number

    it 'the actual style used is based upon the effective default style', ->
      style.define 'default', background: '#112233'
      style.define 'other_default', background: '#111111'
      style.define 'custom', color: '#beefed'

      sci2 = Scintilla!
      buffer2 = Buffer {}, sci2
      style.register_sci sci2, 'other_default'

      style_number = style.number_for 'custom', buffer
      assert.equal '#112233', sci\style_get_back style_number

      style_number = style.number_for 'custom', buffer2
      assert.equal '#111111', sci2\style_get_back style_number

    it 'redefining a default style causes other styles to be rebased upon that', ->
      style.define 'own_style', color: '#334455'

      custom_number = style.number_for 'own_style', buffer
      default_number = style.number_for 'default', buffer

      style.define 'default', background: '#998877'

      -- background should be changed..
      custom_back = sci\style_get_back custom_number
      assert.equal '#998877', custom_back

      -- ..but custom color should still be intact
      custom_fore = sci\style_get_fore custom_number
      assert.equal '#334455', custom_fore

  describe 'define_default(name, definition)', ->
    it 'defines the style only if it is not already defined', ->
      style.define_default 'preset', color: '#334455'
      assert.equal style.preset.color, '#334455'

      style.define_default 'preset', color: '#667788'
      assert.equal style.preset.color, '#334455'

  describe '.number_for(name, buffer [, base])', ->
    it 'returns the assigned style number for name in sci', ->
      assert.equal style.number_for('keyword'), 5 -- default keyword number

    it 'automatically assigns a style number and defines the style in scis if necessary', ->
      style.define 'my_style_a', color: '#334455'
      style.define 'my_style_b', color: '#334455'
      style_num = style.number_for 'my_style_a', buffer
      set_fore = sci\style_get_fore style_num
      assert.equal set_fore, '#334455'
      assert.is_not.equal style.number_for('my_style_b', buffer), style_num

    it 'remembers the style number used for a particular style', ->
      style.define 'got_it', color: '#334455'
      style_num = style.number_for 'got_it', buffer
      style_num2 = style.number_for 'got_it', buffer
      assert.equal style_num2, style_num

    it 'raises an error if the number of styles are #exhausted', ->
      for i = 1, 255 style.define 'my_style' .. i, color: '#334455'

      assert.raises 'Out of style number', ->
        for i = 1, 255 style.number_for 'my_style' .. i, buffer

    it 'returns the default style number if the style is not defined', ->
      assert.equal style.number_for('foo', {}), style.number_for('default', {})

  it '.name_for(number, buffer, sci) returns the style name for number', ->
    assert.equal style.name_for(5, {}), 'keyword' -- default keyword number

    style.define 'whats_in_a_name', color: '#334455'
    style_num = style.number_for 'whats_in_a_name', buffer
    assert.equal style.name_for(style_num, buffer), 'whats_in_a_name'

  describe '.register_sci(sci, default_style)', ->
    it 'defines the default styles in the specified sci', ->
      t = theme.current
      t.styles.keyword = color: '#112233'
      style.set_for_theme t

      sci2 = Scintilla!
      buffer2 = Buffer {}, sci2

      number = style.number_for 'keyword', buffer2
      old = sci2\style_get_fore number
      style.register_sci sci2
      new = sci2\style_get_fore number
      assert.is_not.equal new, old
      assert.equal new, t.styles.keyword.color

    it 'allows specifying a different default style through <default_style>', ->
      t = theme.current
      t.styles.keyword = color: '#223344'
      style.set_for_theme t

      sci2 = Scintilla!
      style.register_sci sci2, 'keyword'
      def_fore = sci2\style_get_fore style.number_for 'default', {}
      def_kfore = sci2\style_get_fore style.number_for 'keyword', {}
      assert.equal t.styles.keyword.color, def_fore

  it '.set_for_buffer(sci, buffer) initializes any previously used buffer styles', ->
    sci2 = Scintilla!
    style.register_sci sci2

    style.define 'style_foo', color: '#334455'
    prev_number = style.number_for 'style_foo', buffer
    style.set_for_buffer sci2, buffer

    defined_fore = sci2\style_get_fore prev_number
    assert.equal defined_fore, '#334455'

    new_number = style.number_for 'style_foo', buffer
    assert.equal new_number, prev_number

  it '.at_pos(buffer, pos) returns name and style definition at pos', ->
    style.define 'stylish', color: '#101010'
    buffer = ActionBuffer!
    buffer\insert 'hƏllo', 1, 'keyword'
    buffer\insert 'Bačon', 6, 'stylish'

    name, def = style.at_pos(buffer, 5)
    assert.equal name, 'keyword'
    assert.same def, style.keyword

    name, def = style.at_pos(buffer, 6)
    assert.equal name, 'stylish'
    assert.same def, style.stylish

  context '(extended styles)', ->
    before_each ->
      style.define 'my_base', background: '#112233'
      style.define 'my_style', color: '#334455'

    describe '.number_for(name, buffer, base)', ->
      context 'when base is specified', ->
        it 'automatically defines an extended style based upon the base and specified style', ->
          style_num = style.number_for 'my_style', buffer, 'my_base'
          set_fore = sci\style_get_fore style_num
          set_back = sci\style_get_back style_num
          assert.equal set_fore, '#334455'
          assert.equal set_back, '#112233'
          assert.is_not_nil style['my_base:my_style']

        it 'returns the base style if the specified style is not found', ->
          style_num = style.number_for 'my_unknown_style', buffer, 'my_base'
          assert.equal style.number_for('my_base', buffer), style_num

        context 'when <name> itself specifies an extended style', ->
          it 'extracts the base automatically', ->
            style.define 'my_other_base', background: '#112244'
            style_num = style.number_for 'my_other_base:my_style', buffer
            set_fore = sci\style_get_fore style_num
            set_back = sci\style_get_back style_num
            assert.equal '#334455', set_fore
            assert.equal '#112244', set_back
            assert.is_not_nil style['my_other_base:my_style']

    context 'when one of composing styles is redefined', ->
      it 'updates the extended style definition', ->
        style_num = style.number_for 'my_style', buffer, 'my_base'
        style.define 'my_base', background: '#222222'
        assert.equal '#222222', style['my_base:my_style'].background

        style.define 'my_style', color: '#222222'
        assert.equal '#222222', style['my_base:my_style'].color

        set_fore = sci\style_get_fore style_num
        set_back = sci\style_get_back style_num
        assert.equal set_fore, '#222222'
        assert.equal set_back, '#222222'

    it 'redefining a default style also rebases extended styles', ->
      style_num = style.number_for 'my_style', buffer, 'my_base'

      assert.is_false sci\style_get_bold style_num
      style.define 'default', font: bold: true

      -- font should be bold now
      assert.is_true sci\style_get_bold style_num

      -- ..but custom color should still be intact
      assert.equal '#112233', sci\style_get_back style_num
