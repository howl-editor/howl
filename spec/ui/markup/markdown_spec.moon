m = howl.ui.markup.markdown
{:mode} = howl

describe 'markdown', ->
  render = (text) ->
    st = m text
    st.text, st.styles

  it 'returns the text as is when there is no markup', ->
    text, styles = render 'foo bar'
    assert.equals 'foo bar', text
    assert.same {}, styles

  it 'removes heading markers and styles headings', ->
    text, styles = render '# Title *x*\n#### Deep'
    assert.equals 'Title x\nDeep', text
    assert.same { 1, 'h1', 8, 7, 'strong', 8, 9, 'h3', 13 }, styles

  it 'styles inline code', ->
    text, styles = render 'a `b` c ``d`e``'
    assert.equals 'a b c d`e', text
    assert.same { 3, 'embedded', 4, 7, 'embedded', 10 }, styles

  it 'styles emphasis like the markdown mode does', ->
    text, styles = render '**b** and *i* and __u__'
    assert.equals 'b and i and u', text
    assert.same { 1, 'emphasis', 2, 7, 'strong', 8, 13, 'emphasis', 14 }, styles

  it 'styles nested spans with the enclosing span first', ->
    text, styles = render '**"`x`":** y'
    assert.equals '"x": y', text
    assert.same { 1, 'emphasis', 5, 2, 'embedded', 3 }, styles

  it 'leaves underscores within words and unpaired markers alone', ->
    text, styles = render 'a_b_c is _x_, 2 * 3'
    assert.equals 'a_b_c is x, 2 * 3', text
    assert.same { 10, 'strong', 11 }, styles

  it 'handles escapes and entities', ->
    text = render 'a\\_b\\* &lt;x&gt; &amp;&nbsp;y'
    assert.equals 'a_b* <x> & y', text

  it 'shows only the label of links', ->
    text, styles = render 'see [§2.5](#2.5) and [x][r], [not a link]'
    assert.equals 'see §2.5 and x, [not a link]', text
    assert.same { 5, 'link_label', 10, 15, 'link_label', 16 }, styles

  it 'shows bullets for list items', ->
    text, styles = render '- a *b*\n  * c'
    assert.equals '• a b\n  • c', text
    assert.same { 1, 'operator', 4, 7, 'strong', 8, 11, 'operator', 14 }, styles

  it 'styles the numbers of ordered list items', ->
    text, styles = render '1. x'
    assert.equals '1. x', text
    assert.same { 1, 'operator', 3 }, styles

  it 'shows a bar for block quotes', ->
    text, styles = render '> q'
    assert.equals '│ q', text
    assert.same { 1, 'operator', 4 }, styles

  it 'shows rules as wide as the widest line', ->
    text, styles = render 'abcde\n---\nx'
    assert.equals 'abcde\n─────\nx', text
    assert.same { 7, 'comment', 7 + #'─────' }, styles

  it 'styles indented code, but not indented list or paragraph lines', ->
    text, styles = render '-   item\n    more\n\n        code()\n\n    after\nline\n    not code'
    assert.equals '•   item\n    more\n\n        code()\n\n    after\nline\n    not code', text
    assert.same { 1, 'operator', 4, 30, 'embedded', 36 }, styles

  it 'collapses blank lines and removes trailing ones', ->
    assert.equals 'a\n\nb', (render '\na\n\n\n\nb\n\n')

  it 'handles CRLF line endings', ->
    assert.equals 'a\nb', (render 'a\r\nb')

  describe 'fenced code', ->
    local lexer

    before_each ->
      lexer = spy.new -> { 1, 'keyword', 3 }
      mode.register name: 'md-test', create: -> :lexer

    after_each -> mode.unregister 'md-test'

    it 'removes the fences and highlights the code with the lexer of its language', ->
      text, styles = render '```md-test\nif x\n```\ndone'
      assert.equals 'if x\ndone', text
      assert.same { 1, 'embedded', 5, 1, { 1, 'keyword', 3 }, 'md-test|embedded' }, styles
      assert.spy(lexer).was_called_with 'if x', nil, sub_lexing: true

    it 'styles code in unknown languages as embedded', ->
      text, styles = render '~~~nope\ncode\n~~~'
      assert.equals 'code', text
      assert.same { 1, 'embedded', 5 }, styles

    it 'runs an unclosed fence to the end', ->
      text, styles = render '```\na\n\n# b'
      assert.equals 'a\n\n# b', text
      assert.same { 1, 'embedded', 7 }, styles
