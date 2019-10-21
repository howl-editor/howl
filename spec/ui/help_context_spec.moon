import HelpContext from howl.ui

describe 'HelpContext', ->
  local help
  get_text = -> help\get_buffer!.text

  before_each -> help = HelpContext!

  context 'add_section', ->
    it 'returns text added via add_section', ->
      help\add_section heading: 'hello', text: 'world'
      assert.same 'hello\n\nworld\n', get_text!

    it 'parses text as markup', ->
      help\add_section heading: 'hello', text: '<string>world</>'
      assert.same 'hello\n\nworld\n', get_text!

    it 'concatenates multiple sections add_section', ->
      help\add_section heading: 'title', text: 'line 1'
      help\add_section text: 'line 2'
      assert.same 'title\n\nline 1\n\nline 2\n', get_text!

  context 'add_keys', ->
    it 'returns a table of keys added via add_keys', ->
      help\add_keys ctrl_a: 'line 1'
      help\add_keys f2: 'line 2'
      assert.same 'Keys\nctrl_a line 1\nf2     line 2\n', get_text!

    it 'preserves order in which keys were added', ->
      help\add_keys f3: 'line 1'
      help\add_keys f1: 'line 2'
      help\add_keys f2: 'line 3'
      help\add_keys f5: 'line 4'
      assert.same 'Keys\nf3 line 1\nf1 line 2\nf2 line 3\nf5 line 4\n', get_text!

    it 'maps command names to binding keys', ->
      howl.bindings.push ctrl_t: 'test-command'
      help\add_keys ['test-command']: 'line 1'
      assert.same 'Keys\nctrl_t line 1\n', get_text!

    it 'also accepts list of tables as keys', ->
      help\add_keys {
        {ctrl_b: 'line 1'}
        {ctrl_c: 'line 2'}
        {ctrl_a: 'line 3'}
      }
      assert.same 'Keys\nctrl_b line 1\nctrl_c line 2\nctrl_a line 3\n', get_text!

  it 'puts all sections together before all keys', ->
    help\add_keys ctrl_a: 'line 1'
    help\add_section text: 'section 1'
    help\add_keys ctrl_b: 'line 2'
    help\add_section text: 'section 2'
    assert.same 'section 1\n\nsection 2\n\nKeys\nctrl_a line 1\nctrl_b line 2\n', get_text!

  context 'merge', ->
    it 'merges keys and sections from other contexts', ->
      help\add_keys ctrl_a: 'line 1'
      help\add_section text: 'section 1'
      help2 = HelpContext!
      help2\add_keys ctrl_b: 'line 2'
      help2\add_section text: 'section 2'

      help\merge help2
      assert.same 'section 1\n\nsection 2\n\nKeys\nctrl_a line 1\nctrl_b line 2\n', get_text!


