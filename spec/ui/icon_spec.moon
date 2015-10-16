import icon, style from howl.ui

describe 'icon', ->
  describe '.define(name, definition) and .get(name, style)', ->
    icon.define 'hello-icon',
      text: 'hello'
      font: family: 'Icon Font'

    it 'define custom icons rendered as StyledText', ->
      styled_text = icon.get('hello-icon', 'somestyle')
      assert.same styled_text.text, 'hello'
      icon_base_style = styled_text.styles[2]\match '[^:]+'
      assert.same style[icon_base_style].font, {family: 'Icon Font'}

    it 'allow aliasing other icons', ->
      icon.define 'alias', 'hello-icon'
      assert.equals icon.get('alias'), icon.get('hello-icon')

  describe '.define_default(name, definition)', ->
    it 'only defines name if not already defined', ->
      icon.define 'a-icon',
        text: 'a'
        font: family: 'Icon Font'

      icon.define_default 'a-icon'
        text: 'a-default'
        font: family: 'Icon Font'

      icon.define_default 'b-icon'
        text: 'b-default-1'
        font: family: 'Icon Font'

      icon.define_default 'b-icon'
        text: 'b-default-2'
        font: family: 'Icon Font'

      assert.equals 'a', icon.get('a-icon').text
      assert.equals 'b-default-1', icon.get('b-icon').text

