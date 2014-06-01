import Window, Readline, StyledText, style from howl.ui

describe 'Readline', ->
  window = Window!
  local readline

  before_each -> readline = Readline window

  describe 'read(prompt, input)', ->
    it 'suspends the current coroutine while waiting for submission', ->
      co = coroutine.create -> readline\read 'foo'
      assert coroutine.resume co
      assert.equals "suspended", coroutine.status co

    it 'resumes the coroutine upon submission, causing return of the chosen value', ->
      local value
      coroutine.wrap(-> value = readline\read 'foo: ')!
      readline.text = 'bar'
      readline.keymap.return readline
      assert.equals "bar", value

    it "returns multiple values if the input's value_for does", ->
      local values
      input = value_for: -> 1, nil, 2
      coroutine.wrap(-> values = { readline\read 'foo: ', input } )!
      readline.text = 'bar'
      readline.keymap.return readline
      assert.same { 1, nil, 2 }, values

    it 'returns nil upon cancel', ->
      local value
      coroutine.wrap(-> value = readline\read 'foo: ')!
      readline.text = 'bar'
      readline.keymap.escape readline
      assert.is_nil value

    context 'formatting', ->
      it 'adds the prompt to the underlying buffer', ->
        co = coroutine.create -> readline\read 'foo'
        assert coroutine.resume co
        assert.equals "foo", readline.buffer.text

      it 'adds any specified text to the underlying buffer', ->
        co = coroutine.create -> readline\read 'foo', nil, text: 'bar'
        assert coroutine.resume co
        assert.equals "foobar", readline.buffer.text

      it 'supports using StyledText for the prompt', ->
        styled_prompt = StyledText('foo', {1, 'number', 3})
        co = coroutine.create -> readline\read styled_prompt
        assert coroutine.resume co
        assert.equals "foo", readline.buffer.text
        assert.equal 'number', (style.at_pos(readline.buffer, 1))

      it 'supports using StyledText for the text', ->
        styled_text = StyledText('foo', {1, 'number', 3})
        co = coroutine.create -> readline\read '', nil, text: styled_text
        assert coroutine.resume co
        assert.equals "foo", readline.buffer.text
        assert.equal 'number', (style.at_pos(readline.buffer, 1))

    context 'keymap handling', ->
      it "dispatches any key presses to the input's keymap if present", ->
        input = keymap: a: spy.new -> true
        coroutine.wrap(-> readline\read 'foo: ', input)!
        readline.sci.listener.on_keypress character: 'a', key_name: 'a', key_code: 65
        assert.spy(input.keymap.a).was_called_with(input, readline, nil)

      it "does not process the key press any further if the key was handled by the input", ->
        handled = true
        input = keymap: backspace: spy.new -> handled
        coroutine.wrap(-> readline\read 'foo: ', input)!
        readline.text = 'foo'
        backspace_event = character: '\8', key_name: 'backspace', key_code: 123
        readline.sci.listener.on_keypress backspace_event
        assert.equal 'foo', readline.text
        handled = false
        readline.sci.listener.on_keypress backspace_event
        assert.equal 'fo', readline.text

  describe 'complete(force = false)', ->
    it 'raises an error if the readline is not showing', ->
      assert.raises 'hidden', -> readline\complete!
